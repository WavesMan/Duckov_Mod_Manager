import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

/// WebSocket连接状态
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket消息类型
enum WebSocketMessageType {
  request,
  response,
  heartbeat,
  error,
}

/// WebSocket消息
class WebSocketMessage {
  final String id;
  final WebSocketMessageType type;
  final String action;
  final dynamic data;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  WebSocketMessage({
    required this.id,
    WebSocketMessageType type = WebSocketMessageType.request,
    required this.action,
    this.data,
    DateTime? timestamp,
    this.metadata,
  })  : type = type,
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'action': action,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    'metadata': metadata,
  };

  factory WebSocketMessage.fromJson(Map<String, dynamic> json) {
    return WebSocketMessage(
      id: json['id'] as String,
      type: WebSocketMessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WebSocketMessageType.request,
      ),
      action: json['action'] as String,
      data: json['data'],
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// WebSocket客户端配置
class WebSocketClientConfig {
  final String url;
  final Duration connectTimeout;
  final Duration reconnectInterval;
  final int maxReconnectAttempts;
  final bool autoReconnect;
  final bool enableHeartbeat;
  final Duration heartbeatInterval;
  final Duration requestTimeout;
  final int maxRetryAttempts;
  final bool enableMessageQueue;
  final bool offlineMode;

  const WebSocketClientConfig({
    required this.url,
    this.connectTimeout = const Duration(seconds: 20),
    this.reconnectInterval = const Duration(seconds: 5),
    this.maxReconnectAttempts = 10,
    this.autoReconnect = true,
    this.enableHeartbeat = true,
    this.heartbeatInterval = const Duration(seconds: 30),
    this.requestTimeout = const Duration(seconds: 30),
    this.maxRetryAttempts = 3,
    this.enableMessageQueue = true,
    this.offlineMode = false,
  });
}

/// WebSocket客户端 - 支持自动重连、心跳检测、消息队列
class WebSocketClient {
  final WebSocketClientConfig config;
  
  WebSocketChannel? _channel;
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  
  // 重连管理
  int _reconnectAttempts = 0;
  Timer? _reconnectTimer;
  
  // 心跳管理
  Timer? _heartbeatTimer;
  DateTime? _lastHeartbeatTime;
  int _heartbeatCount = 0;
  
  // 消息管理
  final Map<String, Completer<WebSocketMessage>> _pendingRequests = {};
  final StreamController<WebSocketMessage> _messageController = StreamController.broadcast();
  final StreamController<WebSocketConnectionState> _connectionStateController = StreamController.broadcast();
  
  // 消息队列
  final List<WebSocketMessage> _messageQueue = [];
  bool _isProcessingQueue = false;
  
  // 日志
  void Function(String message, {Map<String, dynamic>? metadata})? onLog;
  
  WebSocketClient({
    required this.config,
    this.onLog,
  });
  
  /// 获取当前连接状态
  WebSocketConnectionState get connectionState => _connectionState;
  
  /// 获取连接状态流
  Stream<WebSocketConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// 获取消息流
  Stream<WebSocketMessage> get messageStream => _messageController.stream;
  
  /// 是否已连接
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;
  /// 最近一次心跳时间
  DateTime? get lastHeartbeat => _lastHeartbeatTime;
  /// 已发送心跳次数
  int get heartbeatCount => _heartbeatCount;
  
  /// 连接WebSocket
  Future<void> connect() async {
    // 如果已经连接，则直接返回
    if (_connectionState == WebSocketConnectionState.connected) {
      _log('WebSocket已连接');
      return;
    }

    _setConnectionState(WebSocketConnectionState.connecting);
    _log('正在连接WebSocket: ${config.url}');

    try {
      // 在尝试连接前添加短暂延迟，避免过于频繁的连接尝试
      if (_reconnectAttempts > 0) {
        // 使用指数退避算法增加延迟时间
        final delayMs = math.min(1000 * math.pow(2, _reconnectAttempts - 1), 10000); // 最大10秒
        _log('等待 ${delayMs.toInt()}ms 后重连...');
        await Future.delayed(Duration(milliseconds: delayMs.toInt()));
      }
      
      // 创建WebSocket连接，添加headers以确保正确的握手
      final headers = <String, dynamic>{
        'User-Agent': 'DuckovModManager/1.0',
      };
      
      _log('开始WebSocket连接...');
      final websocket = await WebSocket.connect(
        config.url,
        headers: headers,
      ).timeout(config.connectTimeout);
      
      _log('WebSocket连接建立成功，创建通道...');
      _channel = IOWebSocketChannel(websocket);
      _setConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      
      _log('WebSocket连接成功');
      
      // 启动心跳
      if (config.enableHeartbeat) {
        _startHeartbeat();
      }
      
      // 监听消息
      _log('开始监听消息...');
      _channel!.stream.listen(
        _onMessage,
        onError: _onError,
        onDone: _onDone,
      );
      
      // 处理消息队列
      _processMessageQueue();
      
    } catch (e, stackTrace) {
      _log('WebSocket连接失败: $e\nStack trace: $stackTrace');
      _setConnectionState(WebSocketConnectionState.error);
      
      if (config.autoReconnect && _reconnectAttempts < config.maxReconnectAttempts) {
        _scheduleReconnect();
      } else if (!config.autoReconnect || _reconnectAttempts >= config.maxReconnectAttempts) {
        // 如果不自动重连或者达到最大重连次数，重新设置状态为断开连接
        _setConnectionState(WebSocketConnectionState.disconnected);
      }
      
      // 添加更详细的错误信息
      if (e is WebSocketException) {
        throw e;
      } else {
        throw WebSocketException('连接失败: $e');
      }
    }
  }

  /// 断开连接
  Future<void> disconnect() async {
    _log('正在断开WebSocket连接');
    
    // 取消重连定时器
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    // 取消心跳定时器
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    
    // 关闭通道
    await _channel?.sink.close();
    _channel = null;
    
    _setConnectionState(WebSocketConnectionState.disconnected);
    _log('WebSocket连接已断开');
  }
  
  /// 发送消息
  Future<WebSocketMessage> sendMessage({
    required String action,
    dynamic data,
    Map<String, dynamic>? metadata,
    Duration? timeout,
  }) async {
    final messageId = _generateMessageId();
    final message = WebSocketMessage(
      id: messageId,
      type: WebSocketMessageType.request,
      action: action,
      data: data,
      metadata: metadata,
    );

    // 如果未连接，加入队列
    if (!isConnected) {
      _log('WebSocket未连接，消息加入队列: $action');
      _messageQueue.add(message);
      
      if (config.autoReconnect) {
        await connect();
      }
      
      return message;
    }

    return await _sendMessageInternal(message, timeout ?? config.requestTimeout);
  }
  
  /// 手动入队消息
  void queueMessage(WebSocketMessage message) {
    _messageQueue.add(message);
    _log('消息已加入队列: ${message.action} (ID: ${message.id})');
  }
  
  /// 队列长度
  int get messageQueueLength => _messageQueue.length;
  
  /// 发送消息（内部方法）
  Future<WebSocketMessage> _sendMessageInternal(WebSocketMessage message, Duration timeout) async {
    try {
      final completer = Completer<WebSocketMessage>();
      _pendingRequests[message.id] = completer;

      final messageJson = jsonEncode(message.toJson());
      _log('发送消息: ${message.action} (ID: ${message.id})');
      
      _channel?.sink.add(messageJson);

      return await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingRequests.remove(message.id);
          throw TimeoutException('请求超时: ${message.action}', timeout);
        },
      );
    } catch (e) {
      _pendingRequests.remove(message.id);
      rethrow;
    }
  }
  
  /// 处理接收到的消息
  void _onMessage(dynamic data) {
    try {
      final jsonData = jsonDecode(data as String);
      final message = WebSocketMessage.fromJson(jsonData as Map<String, dynamic>);
      
      _log('收到消息: ${message.action} (ID: ${message.id})');
      
      // 处理心跳响应
      if (message.action == 'heartbeat') {
        _lastHeartbeatTime = DateTime.now();
        return;
      }
      
      // 处理响应消息
      if (_pendingRequests.containsKey(message.id)) {
        final completer = _pendingRequests.remove(message.id)!;
        completer.complete(message);
      } else {
        // 广播其他消息
        _messageController.add(message);
      }
      
    } catch (e) {
      _log('消息处理错误: $e');
    }
  }
  
  /// 处理错误
  void _onError(error) {
    _log('WebSocket错误: $error');
    _setConnectionState(WebSocketConnectionState.error);
    
    // 只有在连接是活跃状态时才尝试重连
    if (config.autoReconnect && 
        _connectionState != WebSocketConnectionState.disconnected &&
        _connectionState != WebSocketConnectionState.reconnecting) {
      _scheduleReconnect();
    }
  }
  
  /// 处理连接关闭
  void _onDone() {
    _log('WebSocket连接已关闭');
    _setConnectionState(WebSocketConnectionState.disconnected);
    
    // 只有在连接是主动断开时才尝试重连
    if (config.autoReconnect && 
        _connectionState != WebSocketConnectionState.error &&
        _connectionState != WebSocketConnectionState.reconnecting) {
      _scheduleReconnect();
    }
  }
  
  /// 启动心跳
  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(config.heartbeatInterval, (_) {
      if (isConnected) {
        _sendHeartbeat();
      }
    });
  }
  
  /// 发送心跳
  void _sendHeartbeat() {
    try {
      final heartbeatMessage = WebSocketMessage(
        id: _generateMessageId(),
        type: WebSocketMessageType.heartbeat,
        action: 'heartbeat',
        data: {'timestamp': DateTime.now().toIso8601String()},
      );
      
      final messageJson = jsonEncode(heartbeatMessage.toJson());
      _channel?.sink.add(messageJson);
      
      _lastHeartbeatTime = DateTime.now();
      _heartbeatCount += 1;
      _log('发送心跳');
    } catch (e) {
      _log('心跳发送失败: $e');
    }
  }
  
  /// 调度重连
  void _scheduleReconnect() {
    if (_reconnectAttempts >= config.maxReconnectAttempts) {
      _log('已达到最大重连次数，停止重连');
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectAttempts++;
    
    // 使用指数退避算法增加重连间隔，避免过于频繁的重连尝试
    final delay = Duration(
      milliseconds: (config.reconnectInterval.inMilliseconds * 
                    math.pow(1.5, _reconnectAttempts - 1)).toInt()
    );
    
    _log('${delay.inSeconds}秒后开始第$_reconnectAttempts次重连');
    
    _reconnectTimer = Timer(delay, () {
      _setConnectionState(WebSocketConnectionState.reconnecting);
      connect();
    });
  }
  
  /// 处理消息队列
  void _processMessageQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;
    
    _isProcessingQueue = true;
    
    while (_messageQueue.isNotEmpty && isConnected) {
      final message = _messageQueue.removeAt(0);
      if (_channel == null && config.offlineMode) {
        // 离线模式下直接丢弃或标记为已处理
        _log('离线模式，跳过发送队列消息: ${message.action}');
        continue;
      } else {
        try {
          await _sendMessageInternal(message, config.requestTimeout);
        } catch (e) {
          _log('队列消息发送失败: $e');
          // 如果发送失败，重新加入队列
          _messageQueue.insert(0, message);
          break;
        }
      }
    }
    
    _isProcessingQueue = false;
  }
  
  /// 设置连接状态
  void _setConnectionState(WebSocketConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
      _log('连接状态变更: ${state.name}');
    }
  }
  
  /// 生成消息ID
  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
  }
  
  /// 日志记录
  void _log(String message, {Map<String, dynamic>? metadata}) {
    final logMessage = '[WebSocketClient] $message';
    print(logMessage);
    onLog?.call(message, metadata: metadata);
  }
  
  /// 清理资源
  void dispose() {
    disconnect();
    _messageController.close();
    _connectionStateController.close();
  }
}

/// WebSocket异常
class WebSocketException implements Exception {
  final String message;
  
  WebSocketException(this.message);
  
  @override
  String toString() => 'WebSocketException: $message';
}
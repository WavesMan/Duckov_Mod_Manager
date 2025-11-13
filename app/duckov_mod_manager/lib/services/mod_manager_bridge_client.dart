/// ModManagerBridge 客户端 - 与游戏内Bridge API通信
/// 支持TCP JSON-RPC风格的实时模组管理

import 'dart:io';
import 'dart:convert';
import 'dart:async';

class ModManagerBridgeClient {
  static const String _host = '127.0.0.1';
  static const int _port = 38274; // 根据官方API文档，使用默认端口38274
  static const Duration _timeout = Duration(seconds: 5);
  
  Socket? _socket;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _responseController = StreamController.broadcast();
  
  /// 连接状态变更监听
  Stream<bool> get connectionStatusStream {
    if (_socket == null) {
      return Stream.value(false);
    }
    return _socket!.handleError((error) {
      print('[ModManagerBridge] 连接错误: $error');
      _isConnected = false;
    }).map((event) => _isConnected);
  }
  
  /// 连接状态流
  Stream<bool> get isConnectedStream => connectionStatusStream;
  
  /// 响应数据流
  Stream<Map<String, dynamic>> get responseStream => _responseController.stream;
  
  /// 检查连接状态（不自动重连）
  bool get isConnected {
    return _socket != null && _isConnected;
  }
  
  /// 尝试建立连接（如果未连接）
  Future<bool> ensureConnected() async {
    if (isConnected) {
      return true;
    }
    try {
      await connect();
      return true;
    } catch (e) {
      print('[ModManagerBridge] 尝试连接失败: $e');
      return false;
    }
  }
  
  /// 建立TCP连接
  Future<void> connect() async {
    try {
      _socket = await Socket.connect(_host, _port, timeout: _timeout);
      _isConnected = true;
      
      // 监听服务端响应
      _socket!.listen(
        (List<int> data) {
          final response = utf8.decode(data);
          print('[ModManagerBridge] 收到响应: $response');
          
          try {
            final jsonResponse = json.decode(response);
            if (jsonResponse is Map<String, dynamic>) {
              _responseController.add(jsonResponse);
            }
          } catch (e) {
            print('[ModManagerBridge] JSON解析错误: $e');
          }
        },
        onError: (error) {
          print('[ModManagerBridge] 监听错误: $error');
          _isConnected = false;
        },
        onDone: () {
          print('[ModManagerBridge] 连接已断开');
          _isConnected = false;
        },
      );
      
      print('[ModManagerBridge] 已连接到 ${_host}:${_port}');
    } catch (e) {
      print('[ModManagerBridge] 连接失败: $e');
      _isConnected = false;
      throw Exception('无法连接到 ModManagerBridge: $e');
    }
  }
  
  /// 初始化Bridge客户端连接
  Future<void> initialize() async {
    try {
      await connect();
      print('[ModManagerBridge] 客户端初始化成功');
    } catch (e) {
      print('[ModManagerBridge] 客户端初始化失败: $e');
      throw Exception('Bridge客户端初始化失败: $e');
    }
  }
  
  /// 断开连接
  void disconnect() {
    _socket?.close();
    _socket = null;
    _isConnected = false;
    print('[ModManagerBridge] 已断开连接');
  }
  
  /// 发送命令
  Future<Map<String, dynamic>> sendCommand(String command, [Map<String, dynamic>? parameters]) async {
    if (!await ensureConnected()) {
      throw Exception('未连接到 ModManagerBridge');
    }
    
    final request = {
      'command': command,
      'parameters': parameters ?? {},
    };
    
    final requestJson = json.encode(request);
    final requestBytes = utf8.encode(requestJson);
    
    print('[ModManagerBridge] 发送命令: $requestJson');
    
    _socket!.add(requestBytes);
    _socket!.flush();
    
    // 等待响应（超时处理）
    return _waitForResponse().timeout(
      _timeout,
      onTimeout: () {
        throw Exception('命令超时');
      },
    );
  }
  
  /// 等待响应
  Future<Map<String, dynamic>> _waitForResponse() async {
    return await _responseController.stream.first;
  }
  
  /// 获取模组列表
  Future<List<BridgeModInfo>> getModList() async {
    try {
      final response = await sendCommand('get_mod_list');
      
      if (response['status'] == 'success') {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((mod) => BridgeModInfo.fromJson(mod)).toList();
      } else {
        throw Exception('获取模组列表失败: ${response['message']}');
      }
    } catch (e) {
      print('[ModManagerBridge] getModList 错误: $e');
      return [];
    }
  }
  
  /// 获取模组详细信息
  Future<BridgeModInfo?> getModInfo(String modName) async {
    try {
      final response = await sendCommand('get_mod_info', {'ModName': modName});
      
      if (response['status'] == 'success') {
        final Map<String, dynamic> data = response['data'] ?? {};
        return BridgeModInfo.fromJson(data);
      } else {
        print('[ModManagerBridge] 获取模组信息失败: ${response['message']}');
        return null;
      }
    } catch (e) {
      print('[ModManagerBridge] getModInfo 错误: $e');
      return null;
    }
  }
  
  /// 启用模组
  Future<bool> enableMod(String modName) async {
    try {
      final response = await sendCommand('enable_mod', {'ModName': modName});
      
      if (response['status'] == 'success') {
        print('[ModManagerBridge] 模组 $modName 启用成功');
        return true;
      } else {
        print('[ModManagerBridge] 启用模组失败: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('[ModManagerBridge] enableMod 错误: $e');
      return false;
    }
  }
  
  /// 禁用模组
  Future<bool> disableMod(String modName) async {
    try {
      final response = await sendCommand('disable_mod', {'ModName': modName});
      
      if (response['status'] == 'success') {
        print('[ModManagerBridge] 模组 $modName 禁用成功');
        return true;
      } else {
        print('[ModManagerBridge] 禁用模组失败: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('[ModManagerBridge] disableMod 错误: $e');
      return false;
    }
  }
  
  /// 批量操作模组状态
  Future<Map<String, bool>> batchToggleMods(List<String> modNames, bool enable) async {
    final results = <String, bool>{};
    for (final modName in modNames) {
      try {
        results[modName] = enable 
            ? await enableMod(modName) 
            : await disableMod(modName);
      } catch (e) {
        print('[ModManagerBridge] 批量操作模组 $modName 错误: $e');
        results[modName] = false;
      }
    }
    return results;
  }
  
  /// 重新加载所有模组
  Future<bool> reloadAllMods() async {
    try {
      final response = await sendCommand('reload_all_mods');
      return response['status'] == 'success';
    } catch (e) {
      print('[ModManagerBridge] reloadAllMods 错误: $e');
      return false;
    }
  }
  
  /// Ping Bridge服务 - 测试连接是否正常
  Future<bool> ping() async {
    try {
      // 尝试获取ModManagerBridge的详细信息来验证连接
      final response = await sendCommand('get_mod_info', {'ModName': 'ModManagerBridge'});
      
      if (response['status'] == 'success') {
        print('[ModManagerBridge] Bridge服务在线，连接正常');
        return true;
      } else {
        print('[ModManagerBridge] Bridge服务响应异常: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('[ModManagerBridge] Ping测试失败: $e');
      return false;
    }
  }
  
  /// 检查Bridge是否在线（不建立持久连接）
  Future<bool> isBridgeOnline() async {
    try {
      // 尝试连接并发送ping命令
      await connect();
      final isOnline = await ping();
      disconnect();
      return isOnline;
    } catch (e) {
      print('[ModManagerBridge] Bridge在线检查失败: $e');
      return false;
    }
  }
  
  void dispose() {
    disconnect();
    _responseController.close();
  }
}

/// Bridge API 模组信息
class BridgeModInfo {
  final String name;
  final bool enabled;
  final String version;
  final String author;
  final String? description;
  final String? id;
  final String? previewImagePath;
  final String? previewUrl;
  
  BridgeModInfo({
    required this.name,
    required this.enabled,
    required this.version,
    required this.author,
    this.description,
    this.id,
    this.previewImagePath,
    this.previewUrl,
  });
  
  factory BridgeModInfo.fromJson(Map<String, dynamic> json) {
    return BridgeModInfo(
      name: json['name'] ?? '',
      enabled: json['enabled'] ?? false,
      version: json['version'] ?? '1.0.0',
      author: json['author'] ?? 'Unknown',
      description: json['description'],
      id: json['id'],
      previewImagePath: json['previewImagePath'],
      previewUrl: json['previewUrl'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'enabled': enabled,
      'version': version,
      'author': author,
      'description': description,
      'id': id,
      'previewImagePath': previewImagePath,
      'previewUrl': previewUrl,
    };
  }
}

/// 桥接模组信息扩展 - 转换为标准 ModInfo 格式
extension BridgeModInfoExtension on BridgeModInfo {
  /// 根据modName查找本地预览图片路径
  Future<String?> _findPreviewImageForBridgeMod(String modName, [String? gameDirectory, String? workshopPath]) async {
    try {
      // 尝试多种可能的模组目录路径
      final List<String> possiblePaths = [];
      
      // 1. 尝试本地模组路径
      if (gameDirectory != null && gameDirectory.isNotEmpty) {
        final localModPath = '$gameDirectory/Duckov_Data/Mods/$modName';
        possiblePaths.add(localModPath);
      }
      
      // 2. 尝试创意工坊路径（如果有ID）
      if (id != null && id!.isNotEmpty && workshopPath != null && workshopPath.isNotEmpty) {
        final workshopModPath = '$workshopPath/$id';
        possiblePaths.add(workshopModPath);
      }
      
      // 在每个可能的路径中查找预览图片
      for (final modPath in possiblePaths) {
        final previewImagePath = await _findPreviewImageInPath(modPath);
        if (previewImagePath != null) {
          print('[BridgeMod]为模组 $modName 找到本地预览图片: $previewImagePath');
          return previewImagePath;
        }
      }
    } catch (e) {
      print('[BridgeMod]查找预览图片时出错: $e');
    }
    
    return null;
  }
  
  /// 在指定路径中查找预览图片
  Future<String?> _findPreviewImageInPath(String modPath) async {
    try {
      final directory = Directory(modPath);
      if (!await directory.exists()) {
        return null;
      }
      
      final entities = await directory.list().toList();
      
      for (final entity in entities) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last.toLowerCase();
          if (fileName == 'preview.png' || fileName == 'preview.jpg' || 
              fileName == 'preview.jpeg' || fileName == 'preview.webp') {
            return entity.path;
          }
        }
      }
    } catch (e) {
      // 忽略错误
    }
    
    return null;
  }
  
  /// 智能映射常见模组的显示名称和描述
  Future<Map<String, dynamic>> _getSmartDisplayInfo(String modName, [String? gameDirectory, String? workshopPath]) async {
    // 常见模组的中文显示名称映射
    final displayNameMap = {
      'CheatMenu': '作弊菜单',
      'ModManagerBridge': '模组管理器桥接',
      'TestMod': '测试模组',
      'ExampleMod': '示例模组',
      'DebugMenu': '调试菜单',
      'InventoryManager': '物品栏管理器',
      'PlayerStats': '玩家属性',
      'WeaponMods': '武器模组',
      'VehicleMods': '载具模组',
      'GraphicsMod': '图形优化',
      'PerformanceMod': '性能优化',
    };
    
    final descriptionMap = {
      'CheatMenu': '猛攻！！！',
      'ModManagerBridge': 'Bridge API桥接服务',
      'TestMod': '用于测试目的的示例模组',
      'ExampleMod': '展示功能的示例模组',
      'DebugMenu': '开发者调试工具菜单',
      'InventoryManager': '增强物品栏管理功能',
      'PlayerStats': '修改玩家属性和能力',
      'WeaponMods': '武器和射击相关改进',
      'VehicleMods': '载具和交通相关改进',
      'GraphicsMod': '改善游戏视觉效果',
      'PerformanceMod': '提升游戏性能表现',
    };
    
    // 确定预览图片路径：优先级顺序
    String? finalPreviewImagePath;
    
    // 1. 优先使用Bridge API返回的本地图片路径
    if (previewImagePath != null && previewImagePath!.isNotEmpty) {
      finalPreviewImagePath = previewImagePath;
    } 
    // 2. 其次尝试根据modName查找本地预览图片
    else {
      final localPreviewImagePath = await _findPreviewImageForBridgeMod(modName, gameDirectory, workshopPath);
      if (localPreviewImagePath != null) {
        finalPreviewImagePath = localPreviewImagePath;
      }
    }
    
    // 3. 最后回退到网络预览图或默认映射
    if (finalPreviewImagePath == null) {
      if (previewUrl != null && previewUrl!.isNotEmpty) {
        // 网络预览图暂不处理，保持null
        finalPreviewImagePath = null;
      }
    }
    
    return {
      'displayName': displayNameMap[modName] ?? modName,
      'description': descriptionMap[modName] ?? '暂无描述',
      'previewImagePath': finalPreviewImagePath,
    };
  }
  
  /// 转换为标准 ModInfo 格式以便与现有系统兼容（异步版本）
  Future<Map<String, dynamic>> toStandardModInfoAsync() async {
    final smartInfo = await _getSmartDisplayInfo(name);
    
    return {
      'id': id ?? name,
      'name': name,
      'displayName': smartInfo['displayName']!,
      'description': smartInfo['description']!,
      'version': version,
      'enabled': enabled,
      'size': 'N/A',
      'path': '', // Bridge模式下模组路径由游戏管理
      'previewImagePath': smartInfo['previewImagePath'],
      'author': author,
      'isBridgeMod': true,
    };
  }
}

// 创建全局Bridge客户端实例
final modManagerBridgeClient = ModManagerBridgeClient();
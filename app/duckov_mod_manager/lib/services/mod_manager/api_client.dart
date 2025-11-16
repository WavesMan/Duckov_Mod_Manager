import 'dart:convert';
import 'dart:async';
import 'async_websocket_client.dart';

/// ModManagerBridge API客户端 - 符合API标准规范
class ModManagerApiClient {
  final AsyncWebSocketClient _websocketClient;
  final void Function(String message, {Map<String, dynamic>? metadata})? _onLog;
  
  // 请求超时配置
  static const Duration _defaultTimeout = Duration(seconds: 30);
  static const Duration _batchTimeout = Duration(seconds: 60);
  
  // API端点常量
  static const String _getModList = 'get_mod_list';
  static const String _activateMod = 'activate_mod';
  static const String _deactivateMod = 'deactivate_mod';
  static const String _activateMods = 'activate_mods';
  static const String _deactivateMods = 'deactivate_mods';
  static const String _rescanMods = 'rescan_mods';
  
  // 批量操作限制
  static const int _maxBatchSize = 10;
  
  ModManagerApiClient({
    required String url,
    void Function(String message, {Map<String, dynamic>? metadata})? onLog,
  }) : _websocketClient = AsyncWebSocketClient(
    config: const WebSocketClientConfig(
      url: 'ws://localhost:9001',
      autoReconnect: true,
      enableHeartbeat: true,
      heartbeatInterval: Duration(seconds: 30),
      reconnectInterval: Duration(seconds: 5),
      maxReconnectAttempts: 10,
      requestTimeout: Duration(seconds: 30),
      connectTimeout: Duration(seconds: 20),
    ),
    onLog: onLog,
  ), _onLog = onLog;

  /// 获取WebSocket客户端（用于外部监控）
  AsyncWebSocketClient get websocketClient => _websocketClient;
  
  /// 连接API
  Future<void> connect() async {
    _log('连接API');
    await _websocketClient.connect();
    _log('API连接完成');
  }
  
  /// 断开连接
  Future<void> disconnect() async {
    _log('断开API连接');
    await _websocketClient.disconnect();
    _log('API连接已断开');
  }
  
  /// 获取模组列表
  Future<List<ModInfo>> getModList() async {
    final sw = Stopwatch()..start();
    _log('请求模组列表');
    try {
      final response = await _websocketClient.sendMessage(
        action: _getModList,
        data: '',
        timeout: _defaultTimeout,
      );
      
      if (!_isSuccessResponse(response)) {
        throw ModManagerApiException('获取模组列表失败: ${response.data}');
      }
      
      final modsData = _parseResponseData<List<dynamic>>(response);
      final result = modsData.map((modData) => ModInfo.fromJson(modData as Map<String, dynamic>)).toList();
      sw.stop();
      _log('模组列表获取成功', metadata: {
        'count': result.length,
        'duration_ms': sw.elapsedMilliseconds,
      });
      return result;
    } catch (e) {
      sw.stop();
      _log('模组列表获取异常', metadata: {
        'error': e.toString(),
        'duration_ms': sw.elapsedMilliseconds,
      });
      throw ModManagerApiException('获取模组列表失败: $e');
    }
  }
  
  /// 激活模组 (用户操作)
  Future<ActivateModResponse> activateMod(String modName) async {
    _validateModName(modName);
    
    try {
      final sw = Stopwatch()..start();
      _log('激活模组', metadata: {'mod': modName});
      final response = await _websocketClient.sendUserMessage(
        action: _activateMod,
        data: modName,
        timeout: _defaultTimeout,
      );
      
      final success = _isSuccessResponse(response);
      final res = ActivateModResponse(modId: modName, activated: success);
      sw.stop();
      _log('激活模组完成', metadata: {
        'mod': modName,
        'success': success,
        'duration_ms': sw.elapsedMilliseconds,
      });
      return res;
    } catch (e) {
      _log('激活模组失败', metadata: {'mod': modName, 'error': e.toString()});
      throw ModManagerApiException('激活模组失败: $e');
    }
  }
  
  /// 停用模组 (用户操作)
  Future<DeactivateModResponse> deactivateMod(String modName) async {
    _validateModName(modName);
    
    try {
      final sw = Stopwatch()..start();
      _log('停用模组', metadata: {'mod': modName});
      final response = await _websocketClient.sendUserMessage(
        action: _deactivateMod,
        data: modName,
        timeout: _defaultTimeout,
      );
      
      final success = _isSuccessResponse(response);
      final res = DeactivateModResponse(modId: modName, deactivated: success);
      sw.stop();
      _log('停用模组完成', metadata: {
        'mod': modName,
        'success': success,
        'duration_ms': sw.elapsedMilliseconds,
      });
      return res;
    } catch (e) {
      _log('停用模组失败', metadata: {'mod': modName, 'error': e.toString()});
      throw ModManagerApiException('停用模组失败: $e');
    }
  }
  
  /// 批量激活模组（最多10个）(用户操作)
  Future<BatchOperationResponse> activateMods(List<String> modNames) async {
    _validateBatchOperation(modNames);
    
    try {
      final sw = Stopwatch()..start();
      _log('批量激活模组', metadata: {'count': modNames.length});
      final response = await _websocketClient.sendUserMessage(
        action: _activateMods,
        data: jsonEncode(modNames),
        timeout: _batchTimeout,
      );
      
      final res = _parseBatchResponse(response);
      sw.stop();
      _log('批量激活完成', metadata: {
        'processed': res.processed,
        'failed': res.failed,
        'duration_ms': sw.elapsedMilliseconds,
      });
      return res;
    } catch (e) {
      _log('批量激活失败', metadata: {'count': modNames.length, 'error': e.toString()});
      throw ModManagerApiException('批量激活模组失败: $e');
    }
  }
  
  /// 批量停用模组（最多10个）(用户操作)
  Future<BatchOperationResponse> deactivateMods(List<String> modNames) async {
    _validateBatchOperation(modNames);
    
    try {
      final sw = Stopwatch()..start();
      _log('批量停用模组', metadata: {'count': modNames.length});
      final response = await _websocketClient.sendUserMessage(
        action: _deactivateMods,
        data: jsonEncode(modNames),
        timeout: _batchTimeout,
      );
      
      final res = _parseBatchResponse(response);
      sw.stop();
      _log('批量停用完成', metadata: {
        'processed': res.processed,
        'failed': res.failed,
        'duration_ms': sw.elapsedMilliseconds,
      });
      return res;
    } catch (e) {
      _log('批量停用失败', metadata: {'count': modNames.length, 'error': e.toString()});
      throw ModManagerApiException('批量停用模组失败: $e');
    }
  }
  
  /// 重新扫描模组 (系统操作)
  Future<RescanResult> rescanMods() async {
    try {
      final sw = Stopwatch()..start();
      _log('重新扫描模组');
      final response = await _websocketClient.sendMessage(
        action: _rescanMods,
        data: '',
        timeout: _defaultTimeout,
      );
      
      final success = _isSuccessResponse(response);
      sw.stop();
      _log('重新扫描完成', metadata: {
        'success': success,
        'duration_ms': sw.elapsedMilliseconds,
      });
      return RescanResult(success: success);
    } catch (e) {
      _log('重新扫描失败', metadata: {'error': e.toString()});
      throw ModManagerApiException('重新扫描模组失败: $e');
    }
  }
  
  /// 切换模组状态 (用户操作)
  Future<bool> toggleMod(String modName, bool activate) async {
    if (activate) {
      final r = await activateMod(modName);
      return r.activated;
    } else {
      final r = await deactivateMod(modName);
      return r.deactivated;
    }
  }
  
  /// 批量切换模组状态 (用户操作)
  Future<BatchOperationResponse> toggleMods(Map<String, bool> modStates) async {
    final modsToActivate = <String>[];
    final modsToDeactivate = <String>[];
    
    modStates.forEach((modName, shouldActivate) {
      if (shouldActivate) {
        modsToActivate.add(modName);
      } else {
        modsToDeactivate.add(modName);
      }
    });
    
    int processed = 0;
    int failed = 0;
    
    // 批量激活
    if (modsToActivate.isNotEmpty) {
      final activateResult = await activateMods(modsToActivate);
      processed += activateResult.processed;
      failed += activateResult.failed;
    }
    
    // 批量停用
    if (modsToDeactivate.isNotEmpty) {
      final deactivateResult = await deactivateMods(modsToDeactivate);
      processed += deactivateResult.processed;
      failed += deactivateResult.failed;
    }
    
    return BatchOperationResponse(
      processed: processed,
      failed: failed,
    );
  }
  
  /// 获取模组状态
  Future<ModStatus> getModStatus(String modName) async {
    _log('获取模组状态', metadata: {'mod': modName});
    final sw = Stopwatch()..start();
    final modList = await getModList();
    final mod = modList.firstWhere(
      (mod) => mod.name == modName,
      orElse: () => throw ModManagerApiException('模组未找到: $modName'),
    );
    
    final status = ModStatus(
      name: mod.name,
      isActive: mod.isActive ?? false,
      isInstalled: true,
      lastModified: DateTime.now(),
    );
    sw.stop();
    _log('模组状态获取完成', metadata: {
      'mod': modName,
      'active': status.isActive,
      'duration_ms': sw.elapsedMilliseconds,
    });
    return status;
  }
  
  /// 获取所有模组状态
  Future<Map<String, ModStatus>> getAllModStatuses() async {
    _log('获取所有模组状态');
    final sw = Stopwatch()..start();
    final modList = await getModList();
    final statuses = <String, ModStatus>{};
    
    for (final mod in modList) {
      statuses[mod.name] = ModStatus(
        name: mod.name,
        isActive: mod.isActive ?? false,
        isInstalled: true,
        lastModified: DateTime.now(),
      );
    }
    
    sw.stop();
    _log('所有模组状态获取完成', metadata: {
      'count': statuses.length,
      'duration_ms': sw.elapsedMilliseconds,
    });
    return statuses;
  }
  
  /// 验证模组名称
  void _validateModName(String modName) {
    if (modName.isEmpty) {
      _log('参数错误', metadata: {'reason': '模组名称为空'});
      throw ModManagerApiException('模组名称不能为空');
    }
    
    if (modName.length > 100) {
      _log('参数错误', metadata: {'reason': '模组名称过长', 'length': modName.length});
      throw ModManagerApiException('模组名称过长（最大100字符）');
    }
  }
  
  /// 验证批量操作
  void _validateBatchOperation(List<String> modNames) {
    if (modNames.isEmpty) {
      _log('参数错误', metadata: {'reason': '批量操作列表为空'});
      throw ModManagerApiException('模组列表不能为空');
    }
    
    if (modNames.length > _maxBatchSize) {
      _log('参数错误', metadata: {'reason': '批量数量超限', 'count': modNames.length});
      throw ModManagerApiException('批量操作模组数量超过限制（最大$_maxBatchSize个）');
    }
    
    for (final modName in modNames) {
      _validateModName(modName);
    }
  }
  
  /// 检查响应是否成功
  bool _isSuccessResponse(WebSocketMessage response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      return data['success'] == true;
    }
    return false;
  }
  
  /// 解析响应数据
  T _parseResponseData<T>(WebSocketMessage response) {
    if (response.data is Map<String, dynamic>) {
      final data = response.data as Map<String, dynamic>;
      if (data['data'] != null) {
        final dataString = data['data'] as String;
        return jsonDecode(dataString) as T;
      }
    }
    throw ModManagerApiException('响应数据格式错误');
  }
  
  /// 解析批量操作响应
  BatchOperationResponse _parseBatchResponse(WebSocketMessage response) {
    if (!_isSuccessResponse(response)) {
      _log('批量操作响应失败', metadata: {'data': response.data});
      throw ModManagerApiException('批量操作失败: ${response.data}');
    }
    
    final data = response.data as Map<String, dynamic>;
    final message = data['message'] as String? ?? '';
    
    // 解析消息中的成功/失败统计
    final successMatch = RegExp(r'success:\s*(\d+)/(\d+)').firstMatch(message);
    final failedMatch = RegExp(r'false:\s*([^;]+)').firstMatch(message);
    
    int successful = 0;
    int total = 0;
    
    if (successMatch != null) {
      successful = int.parse(successMatch.group(1)!);
      total = int.parse(successMatch.group(2)!);
    }
    
    return BatchOperationResponse(
      processed: successful,
      failed: total - successful,
    );
  }

  void _log(String message, {Map<String, dynamic>? metadata}) {
    final m = '[ModManagerApiClient] $message';
    print(m);
    _onLog?.call(message, metadata: metadata);
  }
}

/// 模组信息 - 符合API标准
class ModInfo {
  final String name;
  final String displayName;
  final String description;
  final String path;
  final bool isActive;
  final bool dllFound;
  final bool isSteamItem;
  final int publishedFileId;
  final String dllPath;
  final bool hasPreview;
  final int priority;
  final String? version;
  final bool? enabled;

  ModInfo({
    String? id,
    required this.name,
    String? displayName,
    String? description,
    String? path,
    bool isActive = false,
    bool dllFound = false,
    bool isSteamItem = false,
    int publishedFileId = 0,
    String dllPath = '',
    bool hasPreview = false,
    int priority = 0,
    this.version,
    this.enabled,
  })  : displayName = displayName ?? name,
        description = description ?? '',
        path = path ?? '',
        isActive = isActive,
        dllFound = dllFound,
        isSteamItem = isSteamItem,
        publishedFileId = publishedFileId,
        dllPath = dllPath,
        hasPreview = hasPreview,
        priority = priority;
  String get id => name;

  factory ModInfo.fromJson(Map<String, dynamic> json) {
    return ModInfo(
      name: json['name'] ?? '',
      displayName: json['displayName'] ?? json['name'] ?? '',
      description: json['description'] ?? '',
      path: json['path'] ?? '',
      isActive: json['isActive'] ?? false,
      dllFound: json['dllFound'] ?? false,
      isSteamItem: json['isSteamItem'] ?? false,
      publishedFileId: json['publishedFileId'] ?? 0,
      dllPath: json['dllPath'] ?? '',
      hasPreview: json['hasPreview'] ?? false,
      priority: json['priority'] ?? 0,
      version: json['version'] as String?,
      enabled: json['enabled'] as bool?,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'displayName': displayName,
    'description': description,
    'path': path,
    'isActive': isActive,
    'dllFound': dllFound,
    'isSteamItem': isSteamItem,
    'publishedFileId': publishedFileId,
    'dllPath': dllPath,
    'hasPreview': hasPreview,
    'priority': priority,
  };
}

/// 模组状态
class ModStatus {
  final String name;
  final bool isActive;
  final bool isInstalled;
  final DateTime lastModified;

  ModStatus({
    required this.name,
    required this.isActive,
    required this.isInstalled,
    required this.lastModified,
  });
}

/// 批量操作响应
class BatchOperationResponse {
  final int processed;
  final int failed;
  BatchOperationResponse({required this.processed, required this.failed});

  factory BatchOperationResponse.fromJson(Map<String, dynamic> json) {
    return BatchOperationResponse(
      processed: json['processed'] ?? 0,
      failed: json['failed'] ?? 0,
    );
  }
}

class ActivateModResponse {
  final String modId;
  final bool activated;
  ActivateModResponse({required this.modId, required this.activated});

  factory ActivateModResponse.fromJson(Map<String, dynamic> json) {
    return ActivateModResponse(
      modId: json['modId'] ?? '',
      activated: json['activated'] ?? false,
    );
  }
}

class DeactivateModResponse {
  final String modId;
  final bool deactivated;
  DeactivateModResponse({required this.modId, required this.deactivated});

  factory DeactivateModResponse.fromJson(Map<String, dynamic> json) {
    return DeactivateModResponse(
      modId: json['modId'] ?? '',
      deactivated: json['deactivated'] ?? false,
    );
  }
}

class RescanResult {
  final bool success;
  RescanResult({required this.success});
}

/// API异常
class ModManagerApiException implements Exception {
  final String message;
  final String? code;
  final dynamic response;
  
  ModManagerApiException(this.message, [this.code, this.response]);
  
  @override
  String toString() => 'ModManagerApiException: $message';
}
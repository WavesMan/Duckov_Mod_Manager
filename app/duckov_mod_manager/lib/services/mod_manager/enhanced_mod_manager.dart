import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;
import '../config_manager.dart';
import 'api_client.dart';
import 'async_websocket_client.dart'; // Changed from websocket_client.dart
import '../mod_manager.dart' as services;

/// 模组管理器增强版 - 集成WebSocket API
class EnhancedModManager {
  // 文件系统管理器（原有功能）
  late final FileSystemModManager _fileSystemManager;
  
  // WebSocket API客户端
  ModManagerApiClient? _apiClient;
  
  // 连接状态
  bool _isApiConnected = false;
  final StreamController<bool> _connectionStateController = StreamController.broadcast();
  
  // 缓存管理
  final Map<String, ModInfo> _modCache = {};
  bool _cacheValid = false;
  DateTime? _lastCacheUpdate;
  
  // 配置
  bool _preferApiOverFileSystem = true;
  bool _autoReconnect = true;
  
  /// 连接状态流
  Stream<bool> get connectionStateStream => _connectionStateController.stream;
  
  /// 是否优先使用API
  bool get preferApiOverFileSystem => _preferApiOverFileSystem;
  set preferApiOverFileSystem(bool value) {
    _preferApiOverFileSystem = value;
    invalidateCache();
  }
  
  /// 是否自动重连
  bool get autoReconnect => _autoReconnect;
  set autoReconnect(bool value) {
    _autoReconnect = value;
  }
  
  /// 是否已连接到API
  bool get isApiConnected => _isApiConnected;
  
  /// 构造函数
  EnhancedModManager({services.ModManager? fileSystemManager, ModManagerApiClient? apiClient}) {
    _fileSystemManager = FileSystemModManager(fileSystemManager: fileSystemManager);
    _apiClient = apiClient ?? ModManagerApiClient(url: 'ws://localhost:9001');
    _initializeApiClient();
  }

  /// 暴露底层WebSocket客户端
  AsyncWebSocketClient get websocketClient => _apiClient!.websocketClient; // Changed from WebSocketClient
  /// 暴露API客户端
  ModManagerApiClient get apiClient => _apiClient!;

  /// 初始化（兼容测试）
  Future<void> initialize() async {}
  
  /// 初始化API客户端
  void _initializeApiClient() {
    _apiClient = ModManagerApiClient(
      url: 'ws://localhost:9001',
      onLog: (message, {metadata}) {
        _log(message, metadata: metadata);
      },
    );
    
    // 监听连接状态
    _apiClient?.websocketClient.connectionStateStream.listen((state) { // Changed from websocketClient to websocketClient
      final wasConnected = _isApiConnected;
      _isApiConnected = state == WebSocketConnectionState.connected;
      
      if (wasConnected != _isApiConnected) {
        _connectionStateController.add(_isApiConnected);
        _log('API连接状态变更: $_isApiConnected');
        
        if (_isApiConnected) {
          // 连接成功后刷新缓存
          invalidateCache();
        }
      }
    });
  }
  
  /// 连接到API
  Future<void> connectToApi() async {
    if (_apiClient == null) {
      throw Exception('API客户端未初始化');
    }
    
    try {
      print('[EnhancedModManager] 开始连接到API...');
      await _apiClient!.connect();
      print('[EnhancedModManager] 成功连接到API');
      _log('成功连接到API');
    } catch (e, stackTrace) {
      _log('连接到API失败: $e\nStack trace: $stackTrace');
      print('[EnhancedModManager] 连接到API失败: $e');
      print('[EnhancedModManager] Stack trace: $stackTrace');
      rethrow;
    }
  }
  
  /// 断开API连接
  Future<void> disconnectFromApi() async {
    if (_apiClient != null) {
      await _apiClient!.disconnect();
      _log('已断开API连接');
    }
  }
  
  /// 获取所有模组（智能选择数据源）
  Future<List<ModInfo>> getAllMods() async {
    final sw = Stopwatch()..start();
    _log('获取所有模组');
    if (_preferApiOverFileSystem && _isApiConnected) {
      try {
        final apiMods = await _apiClient!.getModList();
        _updateCache(apiMods);
        sw.stop();
        _log('从API获取模组完成', metadata: {'count': apiMods.length, 'duration_ms': sw.elapsedMilliseconds});
        return apiMods;
      } catch (e) {
        _log('API获取模组列表失败，回退到文件系统: $e');
        final fsMods = await _getModsFromFileSystem();
        sw.stop();
        _log('从文件系统获取模组完成', metadata: {'count': fsMods.length, 'duration_ms': sw.elapsedMilliseconds});
        return fsMods;
      }
    } else {
      final fsMods = await _getModsFromFileSystem();
      sw.stop();
      _log('从文件系统获取模组完成', metadata: {'count': fsMods.length, 'duration_ms': sw.elapsedMilliseconds});
      return fsMods;
    }
  }

  /// 获取本地模组列表（API格式）
  Future<List<ModInfo>> getLocalMods() async {
    return await _getModsFromFileSystem();
  }

  /// 获取远端模组列表（API）
  Future<List<ModInfo>> getRemoteMods() async {
    if (_apiClient == null) throw Exception('API客户端未初始化');
    return await _apiClient!.getModList();
  }

  /// 同步本地与远端模组列表
  Future<List<ModInfo>> syncMods() async {
    try {
      final remote = await getRemoteMods();
      _updateCache(remote);
      return remote;
    } catch (_) {
      return await getLocalMods();
    }
  }

  /// 版本冲突解决
  Future<ConflictResolution> resolveVersionConflict({required ModInfo localMod, required ModInfo remoteMod}) async {
    // 简化策略：优先远端版本
    final resolvedMod = remoteMod;
    return ConflictResolution(resolved: true, chosen: resolvedMod);
  }
  
  /// 从文件系统获取模组
  Future<List<ModInfo>> _getModsFromFileSystem() async {
    final List<services.LocalModInfo> fileSystemMods = await _fileSystemManager.getDownloadedMods();
    
    // 转换为API格式的ModInfo
    return fileSystemMods.map((fsMod) => ModInfo(
      name: fsMod.name,
      displayName: fsMod.displayName,
      description: fsMod.description,
      path: fsMod.path,
      isActive: fsMod.enabled ?? false,
      dllFound: true, // 文件系统模式假设DLL存在
      isSteamItem: RegExp(r'^\d+$').hasMatch(fsMod.id), // ID为数字的视为Steam模组
      publishedFileId: int.tryParse(fsMod.id) ?? 0,
      dllPath: path.join(fsMod.path, '${fsMod.name}.dll'), // 假设DLL路径
      hasPreview: fsMod.previewImagePath != null,
      priority: 0, // 默认优先级
    )).toList();
  }
  
  /// 激活模组
  Future<ActivateModResponse> activateMod(String modName) async {
    if (_isApiConnected) {
      try {
        return await _apiClient!.activateMod(modName);
      } catch (e) {
        print('[EnhancedModManager] API激活模组失败: $e');
        rethrow;
      }
    } else {
      throw Exception('API未连接，无法激活模组');
  }
  }
  
  /// 停用模组
  Future<DeactivateModResponse> deactivateMod(String modName) async {
    if (_isApiConnected) {
      try {
        return await _apiClient!.deactivateMod(modName);
      } catch (e) {
        _log('API停用模组失败: $e');
        rethrow;
      }
    } else {
      throw Exception('API未连接，无法停用模组');
  }
  }
  
  /// 批量激活模组
  Future<BatchOperationResponse> activateMods(List<String> modNames) async {
    if (_isApiConnected) {
      try {
        return await _apiClient!.activateMods(modNames);
      } catch (e) {
        _log('API批量激活模组失败: $e');
        rethrow;
      }
    } else {
      throw Exception('API未连接，无法批量激活模组');
    }
  }
  
  /// 批量停用模组
  Future<BatchOperationResponse> deactivateMods(List<String> modNames) async {
    if (_isApiConnected) {
      try {
        return await _apiClient!.deactivateMods(modNames);
      } catch (e) {
        _log('API批量停用模组失败: $e');
        rethrow;
      }
    } else {
      throw Exception('API未连接，无法批量停用模组');
    }
  }
  
  /// 切换模组状态
  Future<bool> toggleMod(String modName, bool activate) async {
    if (activate) {
      final r = await activateMod(modName);
      return r.activated;
    } else {
      final r = await deactivateMod(modName);
      return r.deactivated;
    }
  }
  
  /// 批量切换模组状态
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
  
  /// 重新扫描模组
  Future<RescanResult> rescanMods() async {
    if (_isApiConnected) {
      try {
        final result = await _apiClient!.rescanMods();
        if (result.success) {
          invalidateCache();
        }
        return result;
      } catch (e) {
        print('[EnhancedModManager] API重新扫描模组失败: $e');
        rethrow;
      }
    } else {
      throw Exception('API未连接，无法重新扫描模组');
    }
  }
  
  /// 获取模组状态
  Future<ModStatus> getModStatus(String modName) async {
    if (_isApiConnected) {
      try {
        return await _apiClient!.getModStatus(modName);
      } catch (e) {
        print('[EnhancedModManager] API获取模组状态失败: $e');
        rethrow;
      }
    } else {
      // 从缓存或文件系统获取
      final allMods = await getAllMods();
      final mod = allMods.firstWhere(
        (mod) => mod.name == modName,
        orElse: () => throw Exception('模组未找到: $modName'),
      );
      
      return ModStatus(
        name: mod.name,
        isActive: mod.isActive,
        isInstalled: true,
        lastModified: DateTime.now(),
      );
    }
  }
  
  /// 获取所有模组状态
  Future<Map<String, ModStatus>> getAllModStatuses() async {
    if (_isApiConnected) {
      try {
        return await _apiClient!.getAllModStatuses();
      } catch (e) {
        print('[EnhancedModManager] API获取所有模组状态失败: $e');
        rethrow;
      }
    } else {
      final allMods = await getAllMods();
      final statuses = <String, ModStatus>{};
      
      for (final mod in allMods) {
        statuses[mod.name] = ModStatus(
          name: mod.name,
          isActive: mod.isActive,
          isInstalled: true,
          lastModified: DateTime.now(),
        );
      }
      
      return statuses;
    }
  }
  
  /// 更新缓存
  void _updateCache(List<ModInfo> mods) {
    _modCache.clear();
    for (final mod in mods) {
      _modCache[mod.name] = mod;
    }
    _cacheValid = true;
    _lastCacheUpdate = DateTime.now();
    _log('缓存已更新', metadata: {'size': _modCache.length, 'timestamp': _lastCacheUpdate?.toIso8601String()});
  }
  
  /// 使缓存失效
void invalidateCache() {
  _cacheValid = false;
  _modCache.clear();
  _lastCacheUpdate = null;
  _log('缓存已失效');
}
  
  /// 获取缓存统计
  Map<String, dynamic> getCacheStats() {
    return {
      'cacheValid': _cacheValid,
      'cacheSize': _modCache.length,
      'lastUpdate': _lastCacheUpdate?.toIso8601String(),
      'apiConnected': _isApiConnected,
      'preferApi': _preferApiOverFileSystem,
    };
  }
  
  /// 清理资源
  void dispose() {
    disconnectFromApi();
    _connectionStateController.close();
    _log('资源已清理');
  }

  void _log(String message, {Map<String, dynamic>? metadata}) {
    final m = '[EnhancedModManager] $message';
    print(m);
  }
}

/// 文件系统模组管理器（原有功能）
class FileSystemModManager {
  final services.ModManager _legacyManager;
  FileSystemModManager({services.ModManager? fileSystemManager})
      : _legacyManager = fileSystemManager ?? services.ModManager();

  /// 获取已下载的模组列表
  Future<List<services.LocalModInfo>> getDownloadedMods() async {
    return await _legacyManager.getDownloadedMods();
  }
}

class ConflictResolution {
  final bool resolved;
  final ModInfo chosen;
  ConflictResolution({required this.resolved, required this.chosen});
}
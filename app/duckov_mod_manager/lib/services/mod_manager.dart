// mod_manager.dart
/// 模组管理服务 - 对应Flet项目的mod_manager.py功能
/// 支持文件系统管理和WebSocket API的混合模式

import 'dart:io';
import 'package:path/path.dart' as path;
import 'config_manager.dart';
export 'mod_manager/local_mod_models.dart';
import 'mod_manager/local_mod_models.dart';
import 'mod_manager/path_detector.dart';
import 'mod_manager/mod_scanner.dart';
import 'mod_manager/mod_utils.dart';
import 'mod_manager/mod_state_store.dart';
import 'mod_manager/ws_client/core/ws_client_service.dart';





class ModManager {
  String? _workshopPath;
  List<LocalModInfo>? _cachedMods;
  bool _cacheValid = false;
  
  // 本地模组缓存
  List<LocalModInfo>? _cachedLocalMods;
  bool _localCacheValid = false;
  
  // 管理模式配置
  ModManagementMode _currentMode = ModManagementMode.fileSystem;
  final WorkshopPathDetector _detector = WorkshopPathDetector();
  late final ModScanner _scanner = ModScanner(_log);
  late final ModStateStore _stateStore = ModStateStore();
  Future<void>? _stateInit;
  
  /// 获取当前管理模式
  ModManagementMode get currentMode => _currentMode;
  
  /// 设置管理模式
  void setManagementMode(ModManagementMode mode) {
    _currentMode = mode;
    _invalidateCache(); // 清除缓存以应用新模式
  }
  
  /// 构造函数 - 在初始化时立即读取并应用已保存的配置
  ModManager() {
    // 立即初始化创意工坊路径，使用已保存的配置
    _updateWorkshopPath();
    _stateInit = _stateStore.init();
    configManager.addListener(_onConfigChanged);
    WsClientService.instance.start();
  }

  /// 更新创意工坊路径
  void _updateWorkshopPath() {
    final gameDirectory = configManager.get('game_directory');
    String? result;
    if (gameDirectory != null && gameDirectory is String && gameDirectory.isNotEmpty) {
      if (_detector.isValidGameDirectoryPath(gameDirectory)) {
        final dir = Directory(gameDirectory);
        if (dir.existsSync() && _detector.isValidGameDirectory(gameDirectory)) {
          final detected = _detector.detectWorkshopPathFromGameDirectory(gameDirectory);
          if (detected != null && Directory(detected).existsSync()) {
            result = detected;
          }
        }
      }
    }
    _workshopPath = result ?? _detector.getDefaultWorkshopPath();
    _invalidateCache();
  }

  /// 获取用户选择的游戏目录对应的创意工坊路径
  String? _getUserWorkshopPath() {
    return null;
  }

  /// 验证游戏目录路径格式
  bool _isValidGameDirectoryPath(String path) => _detector.isValidGameDirectoryPath(path);

  /// 验证游戏目录是否包含有效的游戏文件
  bool _isValidGameDirectory(String gameDirectory) => _detector.isValidGameDirectory(gameDirectory);

  /// 处理路径错误
  void _handlePathError(String errorMessage) {}

  /// 根据游戏目录自动检测创意工坊路径
  String? _detectWorkshopPathFromGameDirectory(String gameDirectory) =>
      _detector.detectWorkshopPathFromGameDirectory(gameDirectory);

  /// 获取默认创意工坊路径
  String _getDefaultWorkshopPath() => _detector.getDefaultWorkshopPath();

  /// 使缓存失效（对外暴露的公共方法）
  void invalidateCache() {
    _invalidateCache();
  }

  /// 使缓存失效
  void _invalidateCache() {
    _cacheValid = false;
    _cachedMods = null;
    _localCacheValid = false;
    _cachedLocalMods = null;
    _log('所有缓存已清空');
  }

  /// 强制刷新创意工坊路径（当用户更改游戏目录后调用）
  void refreshWorkshopPath() {
    _log('强制刷新创意工坊路径');
    _updateWorkshopPath();
  }

  /// 获取已下载的模组列表
  Future<List<LocalModInfo>> getDownloadedMods() async {
    final sw = Stopwatch()..start();
    _log('获取已下载模组');
    // 检查是否有有效缓存
    if (_cacheValid && _cachedMods != null) {
      _log('使用缓存的模组列表');
      return _cachedMods!;
    }

    _updateWorkshopPath();

    if (_workshopPath == null || !await Directory(_workshopPath!).exists()) {
      _log('工作坊路径不存在: $_workshopPath');
      return [];
    }

    final downloadedMods = await _scanner.scanWorkshopMods(_workshopPath!);
    await (_stateInit ?? Future.value());
    final enabledMap = await _stateStore.getEnabledMap(downloadedMods.map((m) => m.id));
    final merged = downloadedMods.map((m) {
      final e = enabledMap[m.id];
      return e == null ? m : m.copyWith(enabled: e);
    }).toList();

    _log('找到 ${merged.length} 个已下载的模组');

    // 缓存结果
    _cachedMods = merged;
    _cacheValid = true;

    sw.stop();
    _log('获取已下载模组完成', metadata: {'count': merged.length, 'duration_ms': sw.elapsedMilliseconds});
    return merged;
  }

  /// 获取已下载的模组列表（分页版本）
  Future<({List<LocalModInfo> mods, int totalPages})> getDownloadedModsPaginated({
    int page = 1,
    int pageSize = 16,
  }) async {
    final allMods = await getDownloadedMods();
    final totalMods = allMods.length;
    final totalPages = (totalMods + pageSize - 1) ~/ pageSize; // 向上取整

    // 计算起始和结束索引
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    // 切片获取当前页的模组
    final pageMods = allMods.sublist(
      startIndex.clamp(0, totalMods),
      endIndex.clamp(0, totalMods),
    );

    return (mods: pageMods, totalPages: totalPages);
  }

  /// 获取模组详细信息
  Future<LocalModInfo> _getModInfo(String modId, String modPath) async {
    return await _scanner.getModInfo(modId, modPath);
  }

  Future<String?> _findPreviewImage(String modPath) async => await findPreviewImage(modPath);

  /// 获取本地模组列表
  Future<List<LocalModInfo>> getLocalMods() async {
    final sw = Stopwatch()..start();
    _log('获取本地模组');
    // 检查是否有有效缓存
    if (_localCacheValid && _cachedLocalMods != null) {
      _log('使用缓存的本地模组列表');
      return _cachedLocalMods!;
    }
    
    _log('获取本地模组列表');
    
    // 获取游戏目录路径
    final gameDirectory = configManager.get('game_directory');
    if (gameDirectory == null || gameDirectory is! String || gameDirectory.isEmpty) {
      _log('未设置游戏目录，无法获取本地模组');
      return [];
    }
    
    final localMods = await _scanner.scanLocalMods(gameDirectory);
    await (_stateInit ?? Future.value());
    final enabledMap = await _stateStore.getEnabledMap(localMods.map((m) => m.id));
    final merged = localMods.map((m) {
      final e = enabledMap[m.id];
      return e == null ? m : m.copyWith(enabled: e);
    }).toList();
    
    _log('找到 ${merged.length} 个本地模组');
    
    // 缓存结果
    _cachedLocalMods = merged;
    _localCacheValid = true;
    
    sw.stop();
    _log('获取本地模组完成', metadata: {'count': merged.length, 'duration_ms': sw.elapsedMilliseconds});
    return merged;
  }

  /// 获取本地模组详细信息
  Future<LocalModInfo> _getLocalModInfo(String modName, String modPath) async {
    return await _scanner.getLocalModInfo(modName, modPath);
  }

  Future<String> _getDirectorySize(String dirPath) async => await getDirectorySize(dirPath);

  /// 检查模组是否已下载
  Future<bool> isModDownloaded(String modId) async {
    if (modId.isEmpty) return false;

    _updateWorkshopPath();

    if (_workshopPath == null) {
      _log('作坊路径为空');
      return false;
    }

    try {
      final modDir = Directory(path.join(_workshopPath!, modId));
      return await modDir.exists();
    } catch (e) {
      _log('检查模组下载状态时出错: $e');
      return false;
    }
  }

  /// 排序模组列表
  List<LocalModInfo> sortMods(List<LocalModInfo> mods, String sortBy, {bool reverse = false}) {
    switch (sortBy) {
      case 'name':
        mods.sort((a, b) => a.displayName.compareTo(b.displayName));
        break;
      case 'version':
        mods.sort((a, b) => a.version.compareTo(b.version));
        break;
      case 'size':
        // 简单的文件大小比较，实际可能需要解析大小字符串
        break;
      case 'enabled':
        // 先按启用状态排序，再按名称排序
        mods.sort((a, b) {
          final aEnabled = a.enabled ?? false;
          final bEnabled = b.enabled ?? false;
          if (aEnabled != bEnabled) {
            return aEnabled ? -1 : 1;
          }
          return a.displayName.compareTo(b.displayName);
        });
        break;
      default:
        // 默认按名称排序
        mods.sort((a, b) => a.displayName.compareTo(b.displayName));
    }

    if (reverse) {
      mods = mods.reversed.toList();
    }

    return mods;
  }

  // 已移除Bridge相关功能

  /// 批量启用模组
  Future<Map<String, bool>> batchEnableMods(List<String> modIds) async {
    final results = <String, bool>{};
    for (final modId in modIds) {
      try {
        final result = await enableMod(modId);
        results[modId] = result;
    } catch (e) {
        _log('启用模组 $modId 时出错: $e');
        results[modId] = false;
      }
    }
    try {
      WsClientService.instance.applyBatch(modIds, const <String>[]);
    } catch (_) {}
    return results;
  }

  /// 批量禁用模组
  Future<Map<String, bool>> batchDisableMods(List<String> modIds) async {
    final results = <String, bool>{};
    for (final modId in modIds) {
      try {
        final result = await disableMod(modId);
        results[modId] = result;
    } catch (e) {
        _log('禁用模组 $modId 时出错: $e');
        results[modId] = false;
      }
    }
    try {
      WsClientService.instance.applyBatch(const <String>[], modIds);
    } catch (_) {}
    return results;
  }

  /// 启用模组
  Future<bool> enableMod(String modId) async {
    await (_stateInit ?? Future.value());
    await _stateStore.setEnabled(modId, true);
    _log('启用模组: $modId');
    _invalidateCache();
    try {
      WsClientService.instance.applyLocalChange(modId, true);
    } catch (_) {}
    return true;
  }

  /// 禁用模组
  Future<bool> disableMod(String modId) async {
    await (_stateInit ?? Future.value());
    await _stateStore.setEnabled(modId, false);
    _log('禁用模组: $modId');
    _invalidateCache();
    try {
      WsClientService.instance.applyLocalChange(modId, false);
    } catch (_) {}
    return true;
  }

  /// 获取智能分页模组列表
  Future<({List<LocalModInfo> mods, int totalPages})> getSmartModsPaginated({
    int page = 1,
    int pageSize = 16,
  }) async {
    // 目前直接调用getDownloadedModsPaginated
    return await getDownloadedModsPaginated(page: page, pageSize: pageSize);
  }

  Future<bool> isBridgeConnected() async {
    return WsClientService.instance.isConnected;
  }

  Future<bool> isModEnabled(String modId) async {
    await (_stateInit ?? Future.value());
    final v = await _stateStore.getEnabled(modId);
    return v ?? false;
  }

  /// 兼容UI：初始化Bridge连接（文件系统模式下为空实现）
  Future<void> initializeBridgeConnection() async {
    await WsClientService.instance.start();
  }

  /// 清理资源
  void dispose() {
    _log('资源已清理');
    _stateStore.dispose();
    configManager.removeListener(_onConfigChanged);
    try {
      WsClientService.instance.stop();
    } catch (_) {}
  }

  void _onConfigChanged(String key, dynamic value) {
    if (key == 'game_directory') {
      _updateWorkshopPath();
    }
  }

  void _log(String message, {Map<String, dynamic>? metadata}) {
    final m = '[ModManager] $message';
    print(m);
  }
}

// 已移除扩展，copyWith 在模型定义文件中提供

// 创建全局模组管理器实例
final modManager = ModManager();
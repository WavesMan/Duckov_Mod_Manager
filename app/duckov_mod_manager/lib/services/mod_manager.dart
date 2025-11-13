// mod_manager.dart
/// 模组管理服务 - 对应Flet项目的mod_manager.py功能

import 'dart:io';
import 'dart:convert';
import 'dart:isolate';
import 'package:path/path.dart' as path;
import 'config_manager.dart';

class ModInfo {
  final String id;
  final String path;
  final String name;
  final String displayName;
  final String description;
  final String version;
  final String size;
  final String? previewImagePath;

  ModInfo({
    required this.id,
    required this.path,
    required this.name,
    required this.displayName,
    required this.description,
    required this.version,
    required this.size,
    this.previewImagePath,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'name': name,
    'display_name': displayName,
    'description': description,
    'version': version,
    'size': size,
    'preview_image_path': previewImagePath,
  };
}

class ModManager {
  String? _workshopPath;
  List<ModInfo>? _cachedMods;
  bool _cacheValid = false;
  
  // 本地模组缓存
  List<ModInfo>? _cachedLocalMods;
  bool _localCacheValid = false;

  /// 构造函数 - 在初始化时立即读取并应用已保存的配置
  ModManager() {
    // 立即初始化创意工坊路径，使用已保存的配置
    _updateWorkshopPath();
  }

  /// 更新创意工坊路径
  void _updateWorkshopPath() {
    // 优先使用用户选择的游戏目录对应的创意工坊路径
    final userWorkshopPath = _getUserWorkshopPath();
    if (userWorkshopPath != null) {
      _workshopPath = userWorkshopPath;
      print('[ModManager]使用用户选择的游戏目录对应的创意工坊路径: $_workshopPath');
    } else {
      // 回退到默认路径
      _workshopPath = _getDefaultWorkshopPath();
      print('[ModManager]使用默认创意工坊路径: $_workshopPath');
    }
    _invalidateCache();
  }

  /// 获取用户选择的游戏目录对应的创意工坊路径
  String? _getUserWorkshopPath() {
    try {
      // 从配置管理器获取用户选择的游戏目录
      final gameDirectory = configManager.get('game_directory');
      
      if (gameDirectory != null && gameDirectory is String && gameDirectory.isNotEmpty) {
        print('[ModManager]检测到用户选择的游戏目录: $gameDirectory');
        
        // 验证游戏目录路径格式
        if (!_isValidGameDirectoryPath(gameDirectory)) {
          print('[ModManager]游戏目录路径格式无效: $gameDirectory');
          return null;
        }
        
        // 验证游戏目录是否存在
        final gameDir = Directory(gameDirectory);
        if (!gameDir.existsSync()) {
          print('[ModManager]用户选择的游戏目录不存在: $gameDirectory');
          _handlePathError('游戏目录不存在: $gameDirectory');
          return null;
        }
        
        // 验证游戏目录是否包含游戏相关文件
        if (!_isValidGameDirectory(gameDirectory)) {
          print('[ModManager]游戏目录不包含有效的游戏文件: $gameDirectory');
          _handlePathError('选择的目录不包含有效的游戏文件');
          return null;
        }
        
        // 根据游戏目录自动检测创意工坊路径
        final workshopPath = _detectWorkshopPathFromGameDirectory(gameDirectory);
        if (workshopPath != null && Directory(workshopPath).existsSync()) {
          print('[ModManager]检测到创意工坊路径: $workshopPath');
          return workshopPath;
        } else {
          print('[ModManager]无法检测到有效的创意工坊路径');
          _handlePathError('无法找到对应的创意工坊目录');
        }
      }
    } catch (e) {
      print('[ModManager]获取用户选择的游戏目录时出错: $e');
      _handlePathError('读取游戏目录配置时出错: $e');
    }
    
    return null;
  }

  /// 验证游戏目录路径格式
  bool _isValidGameDirectoryPath(String path) {
    if (path.isEmpty) return false;
    
    // 检查路径是否包含非法字符
    final invalidChars = ['<', '>', '"', '|', '?', '*'];
    for (final char in invalidChars) {
      if (path.contains(char)) {
        return false;
      }
    }
    
    // 检查路径是否为绝对路径
    // Windows路径格式: C:\ 或 C:/
    // Unix路径格式: /
    if (!path.startsWith(RegExp(r'[A-Z]:[\\/]|/'))) {
      return false;
    }
    
    return true;
  }

  /// 验证游戏目录是否包含有效的游戏文件
  bool _isValidGameDirectory(String gameDirectory) {
    try {
      final dir = Directory(gameDirectory);
      final entities = dir.listSync();
      
      // 检查常见的游戏相关文件或目录
      final gameFiles = [
        'Escape from Duckov.exe',
        'duckov.exe',
        'game.exe',
        'Mods',
        'Saves',
        'Config',
        'Data',
        'duckov',
        'escape from duckov'
      ];
      
      for (final entity in entities) {
        final fileName = entity.path.split(Platform.pathSeparator).last.toLowerCase();
        for (final gameFile in gameFiles) {
          if (fileName.contains(gameFile.toLowerCase())) {
            return true;
          }
        }
      }
      
      // 如果是Steam目录结构，检查上级目录
      if (gameDirectory.contains('steamapps') && gameDirectory.contains('common')) {
        return true; // Steam标准目录结构视为有效
      }
      
      return false;
    } catch (e) {
      print('[ModManager]验证游戏目录时出错: $e');
      return false;
    }
  }

  /// 处理路径错误
  void _handlePathError(String errorMessage) {
    // 这里可以添加错误日志记录或用户通知
    // 目前先打印到控制台
    print('[ModManager]路径错误: $errorMessage');
    
    // 可以在这里添加错误回调或事件通知
    // 例如：_onPathError?.call(errorMessage);
  }

  /// 根据游戏目录自动检测创意工坊路径
  String? _detectWorkshopPathFromGameDirectory(String gameDirectory) {
    try {
      final gameDir = Directory(gameDirectory);
      
      // 检查是否是Steam游戏目录结构
      if (gameDirectory.contains('steamapps') && gameDirectory.contains('common')) {
        // Steam标准目录结构: .../steamapps/common/Escape from Duckov
        final steamappsDir = gameDir.parent.parent;
        final workshopPath = path.join(steamappsDir.path, 'workshop', 'content', '3167020');
        
        if (Directory(workshopPath).existsSync()) {
          return workshopPath;
        }
      }
      
      // 检查是否是直接的游戏安装目录
      // 尝试在游戏目录的上级目录中寻找workshop目录
      final parentDir = gameDir.parent;
      final workshopPath = path.join(parentDir.path, 'workshop', 'content', '3167020');
      if (Directory(workshopPath).existsSync()) {
        return workshopPath;
      }
      
      // 检查游戏目录本身是否包含Duckov_Data/Mods子目录（本地模组）
      final modsPath = path.join(gameDirectory, 'Duckov_Data', 'Mods');
      if (Directory(modsPath).existsSync()) {
        return modsPath;
      }
      
    } catch (e) {
      print('[ModManager]检测创意工坊路径时出错: $e');
    }
    
    return null;
  }

  /// 获取默认创意工坊路径
  String _getDefaultWorkshopPath() {
    // Windows默认路径
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    return path.join(userProfile, 'AppData', 'LocalLow', 'TeamSoda', 'Duckov', 'Mods');
  }

  /// 使缓存失效
  void _invalidateCache() {
    _cacheValid = false;
    _cachedMods = null;
    _localCacheValid = false;
    _cachedLocalMods = null;
  }

  /// 强制刷新创意工坊路径（当用户更改游戏目录后调用）
  void refreshWorkshopPath() {
    print('[ModManager]强制刷新创意工坊路径');
    _updateWorkshopPath();
  }

  /// 获取已下载的模组列表
  Future<List<ModInfo>> getDownloadedMods() async {
    // 检查是否有有效缓存
    if (_cacheValid && _cachedMods != null) {
      print('[ModManager]使用缓存的模组列表');
      return _cachedMods!;
    }

    _updateWorkshopPath();

    if (_workshopPath == null || !await Directory(_workshopPath!).exists()) {
      print('[ModManager]工作坊路径不存在: $_workshopPath');
      return [];
    }

    final downloadedMods = <ModInfo>[];
    try {
      final directory = Directory(_workshopPath!);
      final entities = await directory.list().toList();

      // 使用多线程并发处理模组信息获取
      final futures = <Future<ModInfo>>[];
      for (final entity in entities) {
        if (entity is Directory) {
          final modId = path.basename(entity.path);
          // 检查目录名是否为数字（模组ID）
          if (RegExp(r'^\d+$').hasMatch(modId)) {
            futures.add(_getModInfo(modId, entity.path));
          }
        }
      }
      
      // 并发执行所有模组信息获取任务
      downloadedMods.addAll(await Future.wait(futures));
    } catch (e) {
      print('[ModManager]获取已下载模组时出错: $e');
    }

    print('[ModManager]找到 ${downloadedMods.length} 个已下载的模组');

    // 缓存结果
    _cachedMods = downloadedMods;
    _cacheValid = true;

    return downloadedMods;
  }

  /// 获取已下载的模组列表（分页版本）
  Future<({List<ModInfo> mods, int totalPages})> getDownloadedModsPaginated({
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
  Future<ModInfo> _getModInfo(String modId, String modPath) async {
    var modInfo = ModInfo(
      id: modId,
      path: modPath,
      name: '模组 $modId',
      displayName: '模组 $modId',
      description: '暂无描述',
      version: '1.0.0',
      size: await _getDirectorySize(modPath),
      previewImagePath: null,
    );

    // 尝试从模组目录中的info.ini文件获取信息
    final infoIniPath = path.join(modPath, 'info.ini');
    final infoIniFile = File(infoIniPath);
    if (await infoIniFile.exists()) {
      try {
        final content = await infoIniFile.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isNotEmpty && trimmedLine.contains('=')) {
            final parts = trimmedLine.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts[1].trim();
              
              switch (key) {
                case 'displayName':
                  modInfo = modInfo.copyWith(displayName: value);
                case 'name':
                  if (modInfo.displayName == '模组 $modId') {
                    modInfo = modInfo.copyWith(displayName: value);
                  }
                  modInfo = modInfo.copyWith(name: value);
                case 'description':
                  modInfo = modInfo.copyWith(description: value);
                case 'version':
                  modInfo = modInfo.copyWith(version: value);
              }
            }
          }
        }
      } catch (e) {
        print('[ModManager]读取info.ini时出错: $e');
      }
    }

    // 尝试查找preview图片
    final previewImagePath = await _findPreviewImage(modPath);
    if (previewImagePath != null) {
      modInfo = modInfo.copyWith(previewImagePath: previewImagePath);
    }

    // 尝试从模组目录中的json文件获取更多信息
    try {
      final directory = Directory(modPath);
      final entities = await directory.list().toList();
      
      for (final entity in entities) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final infoData = json.decode(content);
            
            if (infoData is Map<String, dynamic>) {
              if (infoData.containsKey('name') && modInfo.name == '模组 $modId') {
                modInfo = modInfo.copyWith(name: infoData['name']);
              }
              if (infoData.containsKey('version')) {
                modInfo = modInfo.copyWith(version: infoData['version']);
              }
              break;
            }
          } catch (e) {
            // 忽略JSON解析错误
          }
        }
      }
    } catch (e) {
      // 忽略目录遍历错误
    }

    return modInfo;
  }

  /// 查找模组的预览图片
  Future<String?> _findPreviewImage(String modPath) async {
    try {
      final directory = Directory(modPath);
      final entities = await directory.list().toList();
      
      for (final entity in entities) {
        if (entity is File) {
          final fileName = path.basename(entity.path).toLowerCase();
          if (fileName == 'preview.png' || fileName == 'preview.jpg' || 
              fileName == 'preview.jpeg' || fileName == 'preview.webp') {
            return entity.path;
          }
        }
      }
    } catch (e) {
      print('[ModManager]查找预览图片时出错: $e');
    }
    
    return null;
  }

  /// 获取本地模组列表
  Future<List<ModInfo>> getLocalMods() async {
    // 检查是否有有效缓存
    if (_localCacheValid && _cachedLocalMods != null) {
      print('[ModManager]使用缓存的本地模组列表');
      return _cachedLocalMods!;
    }
    
    print('[ModManager]获取本地模组列表');
    
    // 获取游戏目录路径
    final gameDirectory = configManager.get('game_directory');
    if (gameDirectory == null || gameDirectory is! String || gameDirectory.isEmpty) {
      print('[ModManager]未设置游戏目录，无法获取本地模组');
      return [];
    }
    
    final localModsPath = path.join(gameDirectory, 'Duckov_Data', 'Mods');
    final localModsDir = Directory(localModsPath);
    
    if (!await localModsDir.exists()) {
      print('[ModManager]本地模组目录不存在: $localModsPath');
      return [];
    }
    
    final localMods = <ModInfo>[];
    
    try {
      final entities = await localModsDir.list().toList();
      
      // 使用多线程并发处理本地模组信息获取
      final futures = <Future<ModInfo>>[];
      for (final entity in entities) {
        if (entity is Directory) {
          final modName = path.basename(entity.path);
          futures.add(_getLocalModInfo(modName, entity.path));
        }
      }
      
      // 并发执行所有本地模组信息获取任务
      localMods.addAll(await Future.wait(futures));
    } catch (e) {
      print('[ModManager]获取本地模组时出错: $e');
    }
    
    print('[ModManager]找到 ${localMods.length} 个本地模组');
    
    // 缓存结果
    _cachedLocalMods = localMods;
    _localCacheValid = true;
    
    return localMods;
  }

  /// 获取本地模组详细信息
  Future<ModInfo> _getLocalModInfo(String modName, String modPath) async {
    var modInfo = ModInfo(
      id: modName,
      path: modPath,
      name: modName,
      displayName: modName,
      description: '本地模组 - 暂无描述',
      version: '1.0.0',
      size: await _getDirectorySize(modPath),
      previewImagePath: null,
    );

    // 尝试从模组目录中的info.ini文件获取信息
    final infoIniPath = path.join(modPath, 'info.ini');
    final infoIniFile = File(infoIniPath);
    if (await infoIniFile.exists()) {
      try {
        final content = await infoIniFile.readAsString();
        final lines = content.split('\n');
        
        for (final line in lines) {
          final trimmedLine = line.trim();
          if (trimmedLine.isNotEmpty && trimmedLine.contains('=')) {
            final parts = trimmedLine.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts[1].trim();
              
              switch (key) {
                case 'displayName':
                  modInfo = modInfo.copyWith(displayName: value);
                case 'name':
                  if (modInfo.displayName == modName) {
                    modInfo = modInfo.copyWith(displayName: value);
                  }
                  modInfo = modInfo.copyWith(name: value);
                case 'description':
                  modInfo = modInfo.copyWith(description: value);
                case 'version':
                  modInfo = modInfo.copyWith(version: value);
              }
            }
          }
        }
      } catch (e) {
        print('[ModManager]读取本地模组info.ini时出错: $e');
      }
    }

    // 尝试查找preview图片
    final previewImagePath = await _findPreviewImage(modPath);
    if (previewImagePath != null) {
      modInfo = modInfo.copyWith(previewImagePath: previewImagePath);
    }

    return modInfo;
  }

  /// 计算目录大小并返回格式化字符串
  Future<String> _getDirectorySize(String dirPath) async {
    var totalSize = 0;
    try {
      final directory = Directory(dirPath);
      await for (final entity in directory.list(recursive: true)) {
        if (entity is File) {
          final stat = await entity.stat();
          totalSize += stat.size;
        }
      }
    } catch (e) {
      // 忽略错误
    }

    // 格式化大小
    if (totalSize < 1024) {
      return '$totalSize B';
    } else if (totalSize < 1024 * 1024) {
      return '${totalSize ~/ 1024} KB';
    } else if (totalSize < 1024 * 1024 * 1024) {
      return '${totalSize ~/ (1024 * 1024)} MB';
    } else {
      return '${totalSize ~/ (1024 * 1024 * 1024)} GB';
    }
  }

  /// 检查模组是否已下载
  Future<bool> isModDownloaded(String modId) async {
    if (modId.isEmpty) return false;

    _updateWorkshopPath();

    if (_workshopPath == null) {
      print('[ModManager]作坊路径为空');
      return false;
    }

    final modPath = path.join(_workshopPath!, modId);
    final exists = await Directory(modPath).exists();
    print('[ModManager]检查模组 $modId 是否存在: $exists 路径: $modPath');
    return exists;
  }

  /// 检查模组是否已启用
  Future<bool> isModEnabled(String modId) async {
    try {
      // 获取模组信息以获取显示名称
      final modInfo = await _getModInfo(modId, path.join(_workshopPath ?? '', modId));
      final modName = modInfo.displayName.isNotEmpty ? modInfo.displayName : modInfo.name;

      // 获取Global.json文件路径
      final globalJsonPath = _getGlobalJsonPath();

      // 如果文件不存在，创建一个默认的
      final globalFile = File(globalJsonPath);
      if (!await globalFile.exists()) {
        final defaultContent = {};
        await globalFile.writeAsString(json.encode(defaultContent));
        return false;
      }

      // 读取Global.json文件
      final content = await globalFile.readAsString();
      final globalData = json.decode(content);

      // 检查对应的模组启用状态
      final modKey = 'ModActive_$modName';
      if (globalData.containsKey(modKey) && globalData[modKey] is Map) {
        return globalData[modKey]['value'] ?? false;
      }

      return false;
    } catch (e) {
      print('[ModManager]检查模组启用状态时出错: $e');
      return false;
    }
  }

  /// 启用模组
  Future<bool> enableMod(String modId) async {
    try {
      // 获取源模组路径
      _updateWorkshopPath();
      if (_workshopPath == null) {
        print('[ModManager]工作坊路径为空');
        return false;
      }

      final sourceModPath = path.join(_workshopPath!, modId);
      if (!await Directory(sourceModPath).exists()) {
        print('源模组路径不存在: $sourceModPath');
        return false;
      }

      // 获取模组信息以获取显示名称
      final modInfo = await _getModInfo(modId, sourceModPath);
      final modName = modInfo.displayName.isNotEmpty ? modInfo.displayName : modInfo.name;

      // 获取Global.json文件路径
      final globalJsonPath = _getGlobalJsonPath();

      // 如果文件不存在，创建一个默认的
      final globalFile = File(globalJsonPath);
      Map<String, dynamic> globalData;
      if (!await globalFile.exists()) {
        globalData = {};
      } else {
        final content = await globalFile.readAsString();
        globalData = json.decode(content);
      }

      // 更新模组启用状态
      globalData['ModActive_$modName'] = {
        '__type': 'bool',
        'value': true,
      };

      // 写入修改后的内容
      await globalFile.writeAsString(json.encode(globalData));

      print('[ModManager]模组 $modId ($modName) 启用成功');
      return true;
    } catch (e) {
      print('[ModManager]启用模组时出错: $e');
      return false;
    }
  }

  /// 禁用模组
  Future<bool> disableMod(String modId) async {
    try {
      // 获取源模组路径
      _updateWorkshopPath();
      if (_workshopPath == null) {
        print('[ModManager]工作坊路径为空');
        return false;
      }

      final sourceModPath = path.join(_workshopPath!, modId);
      if (!await Directory(sourceModPath).exists()) {
        print('源模组路径不存在: $sourceModPath');
        return false;
      }

      // 获取模组信息以获取显示名称
      final modInfo = await _getModInfo(modId, sourceModPath);
      final modName = modInfo.displayName.isNotEmpty ? modInfo.displayName : modInfo.name;

      // 获取Global.json文件路径
      final globalJsonPath = _getGlobalJsonPath();

      // 如果文件不存在，创建一个默认的
      final globalFile = File(globalJsonPath);
      Map<String, dynamic> globalData;
      if (!await globalFile.exists()) {
        globalData = {};
      } else {
        final content = await globalFile.readAsString();
        globalData = json.decode(content);
      }

      // 更新模组启用状态
      globalData['ModActive_$modName'] = {
        '__type': 'bool',
        'value': false,
      };

      // 写入修改后的内容
      await globalFile.writeAsString(json.encode(globalData));

      print('[ModManager]模组 $modId ($modName) 禁用成功');
      return true;
    } catch (e) {
      print('[ModManager]禁用模组时出错: $e');
      return false;
    }
  }

  /// 批量启用模组
  Future<Map<String, bool>> batchEnableMods(List<String> modIds) async {
    final results = <String, bool>{};
    for (final modId in modIds) {
      try {
        results[modId] = await enableMod(modId);
      } catch (e) {
        print('[ModManager]启用模组 $modId 时出错: $e');
        results[modId] = false;
      }
    }
    return results;
  }

  /// 批量禁用模组
  Future<Map<String, bool>> batchDisableMods(List<String> modIds) async {
    final results = <String, bool>{};
    for (final modId in modIds) {
      try {
        results[modId] = await disableMod(modId);
      } catch (e) {
        print('[ModManager]禁用模组 $modId 时出错: $e');
        results[modId] = false;
      }
    }
    return results;
  }

  /// 对模组列表进行排序
  List<ModInfo> sortMods(List<ModInfo> mods, String sortBy, {bool reverse = false}) {
    switch (sortBy) {
      case 'name':
        // 按显示名称排序
        mods.sort((a, b) => a.displayName.compareTo(b.displayName));
        if (reverse) mods = mods.reversed.toList();
        return mods;
      case 'status':
        // 按启用状态排序（已启用的在前）
        // 注意：这里需要异步检查状态，暂时按名称排序
        mods.sort((a, b) => a.displayName.compareTo(b.displayName));
        if (reverse) mods = mods.reversed.toList();
        return mods;
      case 'size':
        // 按大小排序
        int parseSize(String sizeStr) {
          try {
            if (sizeStr.endsWith('GB')) {
              return (double.parse(sizeStr.substring(0, sizeStr.length - 2)) * 1024 * 1024 * 1024).toInt();
            } else if (sizeStr.endsWith('MB')) {
              return (double.parse(sizeStr.substring(0, sizeStr.length - 2)) * 1024 * 1024).toInt();
            } else if (sizeStr.endsWith('KB')) {
              return (double.parse(sizeStr.substring(0, sizeStr.length - 2)) * 1024).toInt();
            } else if (sizeStr.endsWith('B')) {
              return int.parse(sizeStr.substring(0, sizeStr.length - 1));
            } else {
              return 0;
            }
          } catch (e) {
            return 0;
          }
        }
        mods.sort((a, b) => parseSize(a.size).compareTo(parseSize(b.size)));
        if (reverse) mods = mods.reversed.toList();
        return mods;
      case 'id':
        // 按ID排序
        mods.sort((a, b) => int.parse(a.id).compareTo(int.parse(b.id)));
        if (reverse) mods = mods.reversed.toList();
        return mods;
      default:
        return mods;
    }
  }

  /// 获取游戏Global.json文件路径
  String _getGlobalJsonPath() {
    // 获取用户数据目录
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    final userDataPath = path.join(userProfile, 'AppData', 'LocalLow', 'TeamSoda', 'Duckov', 'Saves');
    // 确保目录存在
    Directory(userDataPath).createSync(recursive: true);
    return path.join(userDataPath, 'Global.json');
  }
}

// 为ModInfo添加copyWith方法
extension ModInfoCopyWith on ModInfo {
  ModInfo copyWith({
    String? id,
    String? path,
    String? name,
    String? displayName,
    String? description,
    String? version,
    String? size,
    String? previewImagePath,
  }) {
    return ModInfo(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      description: description ?? this.description,
      version: version ?? this.version,
      size: size ?? this.size,
      previewImagePath: previewImagePath ?? this.previewImagePath,
    );
  }
}

// 创建全局模组管理器实例
final modManager = ModManager();
/// 配置管理器，负责配置的加载、保存和管理

import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';

// 配置文件路径
const String configFile = "app_config.json";

// 默认配置
const Map<String, dynamic> defaultConfig = {
  "game_directory": "C:/Games/MyGame/Mods",
  "cache_directory": "C:/Games/MyGame/Cache",
  "temp_directory": "C:/Temp/MyGame",
  "language": "简体中文",
  "auto_update": true,
  "minimize_to_tray": false,
  "animations_enabled": true,
  // 版本检查相关配置
  "last_update_check": null,  // 最后检查更新时间
  "current_version": "0.1.0",  // 当前应用版本
  "skip_version": null,  // 跳过的版本号
};

class ConfigManager {
  static final ConfigManager _instance = ConfigManager._internal();
  
  factory ConfigManager() {
    return _instance;
  }
  
  ConfigManager._internal() {
    _config = Map<String, dynamic>.from(defaultConfig);
    _listeners = <Function(String key, dynamic value)>[];
    _loadConfig();
  }
  
  late Map<String, dynamic> _config;
  late final List<Function(String key, dynamic value)> _listeners;
  
  /// 从配置文件加载配置
  Future<void> _loadConfig() async {
    try {
      final file = File(configFile);
      if (await file.exists()) {
        final contents = await file.readAsString();
        final loadedConfig = json.decode(contents) as Map<String, dynamic>;
        // 合并默认配置和加载的配置，确保所有键都存在
        _config = {...defaultConfig, ...loadedConfig};
        
        // 详细的配置加载日志
        print("\n[ConfigManager] 配置文件加载成功");
        print("[ConfigManager]配置文件路径: ${file.absolute.path}");
        print("[ConfigManager]加载的配置项数量: ${loadedConfig.length}");
        print("[ConfigManager]合并后配置项数量: ${_config.length}");
        print("\n[ConfigManager] 加载的配置文件内容：");
        for (final entry in loadedConfig.entries) {
          print("[ConfigManager] ${entry.key}: ${entry.value}");
        }
        print("\n[ConfigManager] 默认配置项 (未在配置文件中设置)");
        for (final entry in defaultConfig.entries) {
          if (!loadedConfig.containsKey(entry.key)) {
            print("[ConfigManager] ${entry.key}: ${entry.value} (默认值)");
          }
        }
        print("=== 配置加载完成 ===\n");
      } else {
        // 如果配置文件不存在，保存默认配置
        await _saveConfig();
        print("[ConfigManager]配置文件不存在，已创建默认配置文件: $configFile");
      }
    } catch (e) {
      // 静默处理错误，使用默认配置
      _config = Map<String, dynamic>.from(defaultConfig);
    }
  }
  
  /// 保存配置到文件
  Future<void> _saveConfig() async {
    try {
      final file = File(configFile);
      final contents = json.encode(_config);
      await file.writeAsString(contents);
    } catch (e) {
      // 静默处理错误
    }
  }
  
  /// 获取配置项
  dynamic get(String key, {dynamic defaultValue}) {
    return _config[key] ?? defaultValue;
  }
  
  /// 设置配置项
  Future<void> set(String key, dynamic value) async {
    _config[key] = value;
    
    // 通知监听器配置已变更
    _notifyListeners(key, value);
    
    // 自动保存配置
    await _saveConfig();
  }
  
  /// 获取所有配置
  Map<String, dynamic> getAll() {
    return Map<String, dynamic>.from(_config);
  }
  
  /// 重置为默认配置
  Future<void> resetToDefault() async {
    final oldConfig = Map<String, dynamic>.from(_config);
    _config = Map<String, dynamic>.from(defaultConfig);
    
    // 通知监听器所有配置项已重置
    for (final entry in _config.entries) {
      final key = entry.key;
      final value = entry.value;
      final oldValue = oldConfig[key];
      if (oldValue != value) {
        _notifyListeners(key, value);
      }
    }
    
    await _saveConfig();
  }
  
  /// 根据游戏目录获取Steam创意工坊路径
  String? getSteamWorkshopPath() {
    final gameDirectory = get("game_directory", defaultValue: "");
    if (gameDirectory != null && gameDirectory.contains("Escape from Duckov")) {
      // 回退到steamapps目录
      final gameDir = Directory(gameDirectory);
      final steamappsPath = gameDir.parent.parent.path;
      if (steamappsPath.isNotEmpty) {
        // 构造创意工坊路径
        final workshopPath = '$steamappsPath\\workshop\\content\\3167020';
        return workshopPath;
      }
    }
    return null;
  }
  
  /// 选择游戏目录
  Future<String?> selectGameDirectory() async {
    try {
      // 使用file_picker实现Windows API目录选择
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择游戏目录',
        initialDirectory: _config['game_directory'] ?? '',
      );
      
      if (selectedDirectory != null) {
        // 验证路径格式
        if (!_isValidPathFormat(selectedDirectory)) {
          throw Exception('游戏目录路径格式无效。请选择有效的Windows路径（如：C:\\Games\\Escape from Duckov）');
        }
        
        // 验证选择的目录是否存在
        final directory = Directory(selectedDirectory);
        if (!await directory.exists()) {
          throw Exception('选择的目录不存在。请确保路径正确且目录存在');
        }
        
        // 验证目录是否包含游戏相关文件
        final entities = await directory.list().toList();
        bool isGameDirectory = false;
        
        // 检查常见的游戏文件或目录
        for (final entity in entities) {
          final name = entity.path.split(Platform.pathSeparator).last.toLowerCase();
          if (name.contains('duckov.exe') || 
              name.contains('escape from duckov') ||
              name.contains('game.exe') ||
              name.contains('mods') ||
              name.contains('saves') ||
              name.contains('config')) {
            isGameDirectory = true;
            break;
          }
        }
        
        // 如果是Steam标准目录结构，也视为有效
        if (selectedDirectory.contains('steamapps') && selectedDirectory.contains('common')) {
          isGameDirectory = true;
        }
        
        // 如果目录不包含游戏文件，提供明确的指导
        if (!isGameDirectory) {
          // 检查是否是游戏根目录，需要引导到Mods子目录
          final modsPath = '${directory.path}${Platform.pathSeparator}Mods';
          final modsDir = Directory(modsPath);
          if (await modsDir.exists()) {
            return modsPath;
          }
          
          throw Exception('选择的目录不包含游戏文件。请选择包含"Escape from Duckov"游戏的目录，通常是游戏安装目录或Mods文件夹');
        }
        
        return selectedDirectory;
      }
      
      return null;
    } catch (e) {
      rethrow; // 重新抛出异常，让调用方处理
    }
  }
  
  /// 验证路径格式
  bool _isValidPathFormat(String path) {
    if (path.isEmpty) return false;
    
    // 检查路径是否包含非法字符
    final invalidChars = ['<', '>', '"', '|', '?', '*'];
    for (final char in invalidChars) {
      if (path.contains(char)) {
        return false;
      }
    }
    
    // 检查路径是否为绝对路径
    // Windows路径格式: C:\\ 或 C:/
    // Unix路径格式: /
    if (!path.startsWith(RegExp(r'[A-Z]:[\\/]|/'))) {
      return false;
    }
    
    return true;
  }
  
  /// 添加配置变更监听器
  void addListener(Function(String key, dynamic value) listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
    }
  }
  
  /// 移除配置变更监听器
  void removeListener(Function(String key, dynamic value) listener) {
    _listeners.remove(listener);
  }
  
  /// 通知所有监听器
  void _notifyListeners(String key, dynamic value) {
    for (final listener in _listeners) {
      try {
        listener(key, value);
      } catch (e) {
        // 静默处理监听器错误
      }
    }
  }
  
  /// 清除缓存目录
  Future<void> clearCache() async {
    try {
      final cacheDir = get("cache_directory", defaultValue: "");
      if (cacheDir != null && cacheDir.isNotEmpty) {
        final dir = Directory(cacheDir);
        if (await dir.exists()) {
          await dir.delete(recursive: true);
        }
      }
    } catch (e) {
      throw Exception("清除缓存失败");
    }
  }
}

// 创建全局配置管理器实例
final configManager = ConfigManager();
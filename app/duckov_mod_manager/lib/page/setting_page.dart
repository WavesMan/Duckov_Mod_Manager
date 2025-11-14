// setting_page.dart
/// 设置页面 - 基于Flet设置功能重构

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // 添加url_launcher导入
import '../services/theme_manager.dart';
import '../services/config_manager.dart';
import '../services/version_manager.dart';
import '../services/mod_manager.dart';
import 'update_page.dart'; // 添加更新弹窗的导入

class SettingPage extends StatefulWidget {
  const SettingPage({Key? key}) : super(key: key);

  @override
  SettingPageState createState() => SettingPageState();
}

class SettingPageState extends State<SettingPage> {
  late Map<String, dynamic> _config;
  bool _isLoading = false;
  bool _isCheckingUpdate = false;
  Map<String, dynamic>? _updateResult;

  @override
  void initState() {
    super.initState();
    _loadConfig();
    _setupConfigListener();
  }
  
  /// 配置变更监听器
  void _onConfigChanged(String key, dynamic value) {
    // 重新加载配置并更新UI
    if (mounted) {
      setState(() {
        _loadConfig();
      });
    }
  }
  
  /// 设置配置变更监听器
  void _setupConfigListener() {
    configManager.addListener(_onConfigChanged);
  }
  
  @override
  void dispose() {
    // 清理配置变更监听器
    configManager.removeListener(_onConfigChanged);
    super.dispose();
  }

  /// 加载配置
  void _loadConfig() {
    setState(() {
      _config = configManager.getAll();
    });
  }

  /// 更新配置项
  Future<void> _updateConfig(String key, dynamic value) async {
    // 数据一致性校验
    if (!_validateConfigValue(key, value)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('配置值无效，请检查输入'),
            backgroundColor: ThemeManager.getThemeColor('error'),
          ),
        );
      }
      return;
    }
    
    await configManager.set(key, value);
    _loadConfig();
  }
  
  /// 配置值校验
  bool _validateConfigValue(String key, dynamic value) {
    switch (key) {
      case 'game_directory':
        if (value is! String || value.isEmpty) return false;
        return true; // 路径验证在实际使用中处理
      
      case 'auto_update':
      case 'minimize_to_tray':
      case 'animations_enabled':
        return value is bool;
      
      case 'theme_mode':
        const validThemeModes = ['light', 'dark', 'system'];
        return value is String && validThemeModes.contains(value);
      
      case 'language':
        const validLanguages = ['简体中文', 'English', '日本語'];
        return value is String && validLanguages.contains(value);
      
      case 'cache_directory':
      case 'temp_directory':
        if (value is! String || value.isEmpty) return false;
        return true;
      
      default:
        // 其他配置项允许任何值
        return true;
    }
  }

  /// 更新主题模式
  Future<void> _updateThemeMode(String themeMode) async {
    try {
      // 更新配置
      await _updateConfig('theme_mode', themeMode);
      
      // 根据配置值转换为AppThemeMode枚举
      AppThemeMode appThemeMode;
      switch (themeMode) {
        case 'light':
          appThemeMode = AppThemeMode.light;
          break;
        case 'dark':
          appThemeMode = AppThemeMode.dark;
          break;
        case 'system':
        default:
          appThemeMode = AppThemeMode.system;
          break;
      }
      
      // 应用主题模式
      ThemeManager.setThemeMode(appThemeMode);
      
      // 显示成功消息
      if (mounted) {
        String displayName;
        switch (themeMode) {
          case 'light':
            displayName = '浅色模式';
            break;
          case 'dark':
            displayName = '深色模式';
            break;
          case 'system':
          default:
            displayName = '跟随系统';
            break;
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('主题模式已切换到: $displayName'),
            backgroundColor: ThemeManager.getThemeColor('success'),
          ),
        );
      }
      
      // 触发界面重建以应用新主题
      if (mounted) {
        setState(() {
          // 重新加载配置以更新UI
          _loadConfig();
        });
      }
      
      print('[Settings] 主题模式已更新: $themeMode');
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('切换主题模式失败: $e'),
            backgroundColor: ThemeManager.getThemeColor('error'),
          ),
        );
      }
      print('[Settings] 更新主题模式时出错: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: ThemeManager.getThemeColor('background'),
        appBar: AppBar(
          title: const Text('设置'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: ThemeManager.getThemeColor('surface'),
      appBar: AppBar(
        backgroundColor: ThemeManager.getThemeColor('surface'),
        title: Text(
            '设置',
            style: TextStyle(
              color: ThemeManager.getThemeColor('text_primary'),
            ),
        ),
      ),
      body: Stack(
        children: [
          // 可滚动内容区域
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题区域
                _buildHeader(),
                const SizedBox(height: 24),
                
                // 占位空间，为固定按钮栏预留高度
                const SizedBox(height: 60),
                
                // 游戏目录设置
                _buildGameDirectorySection(),
                const SizedBox(height: 24),
                
                // 常规设置
                _buildGeneralSettings(),
                const SizedBox(height: 24),
                
                // 版本检查
                _buildVersionSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
          
          // 固定置顶的按钮栏
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: ThemeManager.getThemeColor('surface'),
                boxShadow: [
                  BoxShadow(
                    color: ThemeManager.getThemeColor('text_primary').withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildActionButtons(),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建标题区域
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      // layout颜色跟随主题：字体用主题文本色，背景交给 Scaffold/Container 控制
      children: [
        Text(
          '设置',
          style: ThemeManager.headingTextStyle(level: 1),
        ),
        const SizedBox(height: 8),
        Text(
          '自定义应用程序设置和偏好',
          style: ThemeManager.bodyTextStyle(size: 14),
        ),
      ],
    );
  }

  /// 构建游戏目录设置区域
  Widget _buildGameDirectorySection() {
    final gameDirectory = _config['game_directory'] ?? '';
    final bool hasValidPath = gameDirectory.isNotEmpty;
    
    return Card(
      color: ThemeManager.getThemeColor('background'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '游戏目录设置',
              style: ThemeManager.headingTextStyle(level: 2),
            ),
            const SizedBox(height: 16),
            
            // 游戏目录路径显示和选择
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '游戏安装路径',
                        style: ThemeManager.headingTextStyle(level: 4),
                      ),
                      const SizedBox(height: 4),
                      
                      if (hasValidPath) ...[
                        Text(
                          gameDirectory,
                          style: ThemeManager.bodyTextStyle(size: 12, color: ThemeManager.getThemeColor('success')),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '✓ 路径有效',
                          style: ThemeManager.bodyTextStyle(size: 10, color: ThemeManager.getThemeColor('success')),
                        ),
                      ] else ...[
                        Text(
                          '未设置游戏目录',
                          style: ThemeManager.bodyTextStyle(size: 12, color: Colors.orange),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '请选择包含"Escape from Duckov"游戏的目录',
                          style: ThemeManager.bodyTextStyle(size: 10, color: Colors.orange),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _selectGameDirectory,
                  child: const Text('浏览'),
                ),
              ],
            ),
            
            // 路径选择说明
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeManager.getThemeColor('primary'),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: ThemeManager.getThemeColor('primary'), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '路径选择说明',
                        style: ThemeManager.headingTextStyle(level: 4, color: ThemeManager.getThemeColor('primary')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '请选择包含"Escape from Duckov"游戏的目录。通常位于：\n'
                    '• Steam版本: E:\\SteamLibrary\\steamapps\\common\\Escape from Duckov\n'
                    '• 本地版本: 游戏安装目录文件夹',
                    style: ThemeManager.bodyTextStyle(size: 10),
                  ),
                ],
              ),
            ),

          ],
        ),
      ),
    );
  }

  /// 选择游戏目录
  Future<void> _selectGameDirectory() async {
    try {
      final selectedPath = await configManager.selectGameDirectory();
      if (selectedPath != null) {
        await _updateConfig('game_directory', selectedPath);
        
        // 刷新模组管理器的创意工坊路径
        try {
          modManager.refreshWorkshopPath();
          print('[Settings] 模组管理器路径已刷新');
        } catch (e) {
          print('[Settings] 刷新模组管理器路径时出错: $e');
        }
        
        // 显示成功消息
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('游戏目录已更新: $selectedPath'),
              backgroundColor: ThemeManager.getThemeColor('success'),
            ),
          );
        }
      }
    } catch (e) {
      // 路径验证失败，清除无效的路径配置
      await _updateConfig('game_directory', '');
      
      // 显示详细的错误信息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: ThemeManager.getThemeColor('error'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: '重新选择',
              onPressed: _selectGameDirectory,
            ),
          ),
        );
      }
      
      print('[Settings] 选择游戏目录失败: $e');
    }
  }

  /// 构建常规设置区域
  Widget _buildGeneralSettings() {
    return Card(
      color: ThemeManager.getThemeColor('background'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '常规设置',
              style: ThemeManager.headingTextStyle(level: 2),
            ),
            const SizedBox(height: 16),
            
            // 主题模式选择
            _buildSettingItem(
              title: '主题模式',
              subtitle: '选择应用程序主题外观',
              trailing: DropdownButton<String>(
                value: _config['theme_mode'] ?? 'system',
                dropdownColor: ThemeManager.getThemeColor('background'),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _updateThemeMode(newValue);
                  }
                },
                items: <String>[
                  'light',
                  'dark', 
                  'system'
                ].map<DropdownMenuItem<String>>((String value) {
                  String displayText;
                  switch (value) {
                    case 'light':
                      displayText = '浅色模式';
                      break;
                    case 'dark':
                      displayText = '深色模式';
                      break;
                    case 'system':
                      displayText = '跟随系统';
                      break;
                    default:
                      displayText = value;
                  }
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(
                        displayText,
                        style: TextStyle(
                          color: ThemeManager.getThemeColor('text_primary'),
                        ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(),
            
            // 自动检查更新
            _buildSettingItem(
              title: '自动检查更新',
              subtitle: '启动时自动检查应用程序更新',
              trailing: Switch(
                value: _config['auto_update'] ?? true,
                onChanged: (value) => _updateConfig('auto_update', value),
              ),
            ),
            const Divider(),
            
            // 最小化到托盘
            _buildSettingItem(
              title: '最小化到托盘',
              subtitle: '关闭窗口时最小化到系统托盘',
              trailing: Switch(
                value: _config['minimize_to_tray'] ?? false,
                onChanged: (value) => _updateConfig('minimize_to_tray', value),
              ),
            ),
            const Divider(),
           
            // // 语言选择
            // _buildSettingItem(
            //   title: '语言',
            //   subtitle: '选择应用程序语言',
            //   trailing: DropdownButton<String>(
            //     value: _config['language'] ?? '简体中文',
            //     onChanged: (String? newValue) {
            //       if (newValue != null) {
            //         _updateConfig('language', newValue);
            //       }
            //     },
            //     items: <String>['简体中文', 'English', '日本語']
            //         .map<DropdownMenuItem<String>>((String value) {
            //       return DropdownMenuItem<String>(
            //         value: value,
            //         child: Text(value),
            //       );
            //     }).toList(),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }



  /// 构建版本检查区域
  Widget _buildVersionSection() {
    final currentVersion = versionManager.getCurrentVersion();
    
    return Card(
      color: ThemeManager.getThemeColor('background'),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '版本信息',
              style: ThemeManager.headingTextStyle(level: 2),
            ),
            const SizedBox(height: 16),
            
            // 当前版本显示
            Row(
              children: [
                Text(
                  '当前版本:',
                  style: ThemeManager.headingTextStyle(level: 4),
                ),
                const SizedBox(width: 8),
                Text(
                  currentVersion,
                  style: ThemeManager.bodyTextStyle(size: 14),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // 检查更新按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingUpdate ? null : _checkForUpdates,
                    icon: _isCheckingUpdate
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 16),
                    label: Text(_isCheckingUpdate ? '检查中...' : '检查更新'),
                  ),
                ),
              ],
            ),
            
            // 更新结果显示
            if (_updateResult != null) ..._buildUpdateResult(),
          ],
        ),
      ),
    );
  }

  /// 构建更新结果显示
  List<Widget> _buildUpdateResult() {
    final result = _updateResult!;
    final hasUpdate = result['has_update'] ?? false;
    final latestVersion = result['latest_version'] ?? '';
    final error = result['error'];
    
    return [
      const SizedBox(height: 16),
      if (error != null)
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: ThemeManager.getThemeColor('error').withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: ThemeManager.getThemeColor('error'), size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '检查更新失败: $error',
                  style: TextStyle(color: ThemeManager.getThemeColor('error')),
                ),
              ),
            ],
          ),
        )
      else
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasUpdate 
                ? ThemeManager.getThemeColor('success').withOpacity(0.1) 
                : ThemeManager.getThemeColor('primary').withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(hasUpdate ? Icons.update : Icons.check_circle, 
                       color: hasUpdate 
                           ? ThemeManager.getThemeColor('success') 
                           : ThemeManager.getThemeColor('primary'), 
                       size: 20),
                  const SizedBox(width: 8),
                  Text(
                    hasUpdate ? '发现新版本: $latestVersion' : '当前已是最新版本',
                    style: TextStyle(
                      color: hasUpdate 
                          ? ThemeManager.getThemeColor('success') 
                          : ThemeManager.getThemeColor('primary'),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (hasUpdate) ...[
                Text(
                  result['release_notes'] as String? ?? '暂无更新说明',
                  style: const TextStyle(fontSize: 12),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () => _showUpdateDialog(result),
                      child: const Text('查看详情'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _openDownloadPage(result['download_url'] ?? ''),
                      child: const Text('前往下载'),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
    ];
  }

  /// 构建操作按钮区域
  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _saveSettings,
            icon: const Icon(Icons.save),
            label: const Text('保存设置'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showResetSettingsDialog,
            icon: const Icon(Icons.restore),
            label: const Text('重置设置'),
          ),
        ),
      ],
    );
  }

  /// 检查更新
  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdate = true;
      _updateResult = null;
    });

    try {
      final result = await versionManager.checkForUpdates();
      setState(() {
        _updateResult = result;
      });
      
      // 如果有更新，直接显示更新弹窗
      final hasUpdate = result['has_update'] as bool? ?? false;
      if (hasUpdate && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showUpdateDialog(result);
        });
      }
    } catch (e) {
      setState(() {
        _updateResult = {'error': e.toString()};
      });
    } finally {
      setState(() {
        _isCheckingUpdate = false;
      });
    }
  }

  /// 打开下载页面
  Future<void> _openDownloadPage(String downloadUrl) async {
    final success = await versionManager.openDownloadPage(downloadUrl);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法打开下载页面')),
      );
    }
  }

  /// 保存设置
  Future<void> _saveSettings() async {
    try {
      // 配置已自动保存，这里只需要显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已保存')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存设置失败: $e')),
        );
      }
    }
  }

  /// 显示重置设置对话框
  Future<void> _showResetSettingsDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('重置设置'),
          content: const Text('确定要重置所有设置为默认值吗？此操作不可撤销。'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetSettings();
              },
              child: const Text('重置'),
            ),
          ],
        );
      },
    );
  }

  /// 重置设置
  Future<void> _resetSettings() async {
    try {
      await configManager.resetToDefault();
      _loadConfig();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('设置已重置为默认值')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('重置设置失败: $e')),
        );
      }
    }
  }

  /// 显示更新弹窗
  Future<void> _showUpdateDialog(Map<String, dynamic> updateInfo) async {
    final result = await showUpdateDialog(context, updateInfo);
    
    if (result == 'workshop') {
      // 打开创意工坊页面
      final workshopUrl = 'https://steamcommunity.com/sharedfiles/filedetails/?id=3603261359';
      try {
        final uri = Uri.parse(workshopUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法打开创意工坊页面')),
          );
        }
      }
    }
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      title: Text(title, style: ThemeManager.headingTextStyle(level: 4)),
      subtitle: Text(subtitle, style: ThemeManager.bodyTextStyle(size: 12)),
      trailing: trailing,
    );
  }

}

/// 便捷函数 - 创建设置页面视图
Widget settingsPageView() {
  return SettingPage();
}
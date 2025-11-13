// config_sync_test.dart
/// 配置同步功能单元测试

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:duckov_mod_manager/services/config_manager.dart';
import 'package:duckov_mod_manager/page/setting_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ConfigManager configManager;
  late SettingPageState settingPageState;
  
  setUp(() {
    configManager = ConfigManager();
  });
  
  tearDown(() async {
    // 测试后清理
    await configManager.resetToDefault();
  });
  
  group('ConfigManager Tests', () {
    test('应该能够正确读取和写入配置', () async {
      // 测试字符串配置
      await configManager.set('game_directory', 'C:/Games/Test');
      expect(configManager.get('game_directory'), 'C:/Games/Test');
      
      // 测试布尔配置
      await configManager.set('auto_update', false);
      expect(configManager.get('auto_update'), false);
      
      // 测试语言配置
      await configManager.set('language', 'English');
      expect(configManager.get('language'), 'English');
    });
    
    test('应该能够获取所有配置', () {
      final allConfig = configManager.getAll();
      expect(allConfig, isNotNull);
      expect(allConfig, isA<Map<String, dynamic>>());
      
      // 验证关键配置项存在
      expect(allConfig.containsKey('game_directory'), true);
      expect(allConfig.containsKey('auto_update'), true);
      expect(allConfig.containsKey('animations_enabled'), true);
      expect(allConfig.containsKey('language'), true);
    });
    
    test('配置变更监听器应该能正常工作', () async {
      bool listenerCalled = false;
      String? receivedKey;
      dynamic receivedValue;
      
      void testListener(String key, dynamic value) {
        listenerCalled = true;
        receivedKey = key;
        receivedValue = value;
      }
      
      // 添加监听器
      configManager.addListener(testListener);
      
      // 修改配置
      await configManager.set('test_key', 'test_value');
      
      // 验证监听器被调用
      expect(listenerCalled, true);
      expect(receivedKey, 'test_key');
      expect(receivedValue, 'test_value');
      
      // 清理监听器
      configManager.removeListener(testListener);
    });
    
    test('重置配置应该通知监听器', () async {
      bool listenerCalled = false;
      String? receivedKey;
      
      void testListener(String key, dynamic value) {
        listenerCalled = true;
        receivedKey = key;
      }
      
      // 添加监听器
      configManager.addListener(testListener);
      
      // 重置配置
      await configManager.resetToDefault();
      
      // 验证监听器被调用
      expect(listenerCalled, true);
      expect(receivedKey, isNotNull);
      
      // 清理监听器
      configManager.removeListener(testListener);
    });
  });
  
  group('SettingPage Tests', () {
    testWidgets('设置页面应该正确显示配置值', (WidgetTester tester) async {
      // 设置初始配置
      await configManager.set('game_directory', 'C:/Test/Game');
      await configManager.set('auto_update', false);
      await configManager.set('animations_enabled', false);
      await configManager.set('language', 'English');
      
      // 构建设置页面
      await tester.pumpWidget(
        MaterialApp(
          home: SettingPage(),
        ),
      );
      
      // 验证页面显示
      expect(find.text('设置'), findsOneWidget);
      expect(find.text('游戏目录设置'), findsOneWidget);
      expect(find.text('常规设置'), findsOneWidget);
    });
    
    testWidgets('Switch组件应该正确响应配置变更', (WidgetTester tester) async {
      await configManager.set('auto_update', true);
      await configManager.set('animations_enabled', true);
      
      await tester.pumpWidget(
        MaterialApp(
          home: SettingPage(),
        ),
      );
      
      // 查找Switch组件并验证初始状态
      final autoUpdateSwitch = find.byType(Switch).first;
      expect(tester.widget<Switch>(autoUpdateSwitch).value, true);
    });
    
    testWidgets('DropdownButton应该正确显示语言选项', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingPage(),
        ),
      );
      
      // 验证语言选项存在
      expect(find.text('简体中文'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('日本語'), findsOneWidget);
    });
  });
  
  group('Config Validation Tests', () {
    test('布尔配置应该只接受布尔值', () {
      // 这里我们直接测试配置管理器的验证逻辑
      // 在实际应用中，这会在_updateConfig方法中处理
      
      // 验证动画设置
      expect(configManager.get('animations_enabled') is bool, true);
      expect(configManager.get('auto_update') is bool, true);
      expect(configManager.get('minimize_to_tray') is bool, true);
    });
    
    test('语言配置应该只接受有效值', () {
      final language = configManager.get('language');
      const validLanguages = ['简体中文', 'English', '日本語'];
      
      expect(validLanguages.contains(language), true);
    });
    
    test('路径配置不应该为空', () {
      final gameDirectory = configManager.get('game_directory');
      expect(gameDirectory, isNotNull);
      
      final cacheDirectory = configManager.get('cache_directory');
      expect(cacheDirectory, isNotNull);
    });
  });
  
  group('Data Consistency Tests', () {
    test('配置变更应该同步到持久化存储', () async {
      final testValue = 'C:/Test/Path/${DateTime.now().millisecondsSinceEpoch}';
      
      await configManager.set('game_directory', testValue);
      
      // 重新创建配置管理器实例来验证持久化
      final newConfigManager = ConfigManager();
      expect(newConfigManager.get('game_directory'), testValue);
    });
    
    test('重置配置应该恢复所有默认值', () async {
      // 修改一些配置
      await configManager.set('auto_update', false);
      await configManager.set('language', 'English');
      
      // 重置配置
      await configManager.resetToDefault();
      
      // 验证恢复默认值
      expect(configManager.get('auto_update'), true); // 默认值为true
      expect(configManager.get('language'), '简体中文'); // 默认值为中文
    });
  });
}
import 'package:flutter/material.dart';
import 'components/layout.dart';
import 'page/home.dart';
import 'page/mod_page.dart';
import 'page/mod_collections_page.dart';
import 'page/steam_workshop_page.dart';
import 'page/setting_page.dart';
import 'services/preload_manager.dart';
import 'services/config_manager.dart';
import 'services/version_manager.dart';
import 'services/collections/collection_service.dart';
import 'services/mod_manager.dart';
import 'services/mod_manager_bridge_client.dart';
import 'services/bridge_sync_service.dart';
import 'page/update_page.dart';

void main() {
  runApp(const DuckovModManagerApp());
}

class DuckovModManagerApp extends StatelessWidget {
  const DuckovModManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Duckov Mod Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        fontFamily: 'MiSans',
      ),
      home: const MainAppLayout(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainAppLayout extends StatefulWidget {
  const MainAppLayout({super.key});

  @override
  State<MainAppLayout> createState() => _MainAppLayoutState();
}

class _MainAppLayoutState extends State<MainAppLayout> {
  int _currentPageIndex = 0;
  
  // 用于避免动画堆积
  bool _isAnimating = false;
  
  // Bridge同步服务
  BridgeSyncService? _bridgeSyncService;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  @override
  void dispose() {
    // 清理Bridge同步服务资源
    _bridgeSyncService?.dispose();
    super.dispose();
  }
  
  /// 初始化应用所需的服务
  Future<void> _initializeServices() async {
    try {
      // 初始化CollectionService
      await collectionService.init();
      debugPrint('CollectionService初始化成功');
      
      // 初始化Bridge同步服务
      await _initializeBridgeSyncService();
      
    } catch (e) {
      debugPrint('服务初始化失败: $e');
    } finally {
      // 无论服务初始化是否成功，都继续检查更新
      _checkForUpdatesOnStartup();
    }
  }
  
  /// 初始化Bridge同步服务
  Future<void> _initializeBridgeSyncService() async {
    try {
      final modManager = ModManager();
      final bridgeClient = ModManagerBridgeClient();
      
      // 等待Bridge客户端连接初始化
      await bridgeClient.initialize();
      
      // 创建并启动Bridge同步服务
      _bridgeSyncService = BridgeSyncService(bridgeClient, modManager);
      _bridgeSyncService?.start();
      
      print('[MainApp] Bridge同步服务初始化成功');
      
    } catch (e) {
      print('[MainApp] Bridge同步服务初始化失败: $e');
      // Bridge同步服务失败不应该阻止应用启动
    }
  }

  /// 启动时检查更新
  Future<void> _checkForUpdatesOnStartup() async {
    // 检查是否启用了自动更新检查
    final autoUpdate = configManager.get('auto_update') as bool? ?? true;
    if (!autoUpdate) return;

    try {
      // 延迟几秒再检查更新，确保应用完全启动
      await Future.delayed(const Duration(seconds: 3));
      
      final result = await versionManager.checkForUpdates();
      final hasUpdate = result['has_update'] as bool;
      
      // 如果有更新，则显示更新弹窗
      if (hasUpdate && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showUpdateDialog(context, result);
        });
      }
    } catch (e) {
      // 静默处理启动时检查更新的错误
      debugPrint('启动时检查更新失败: $e');
    }
  }

  void _onPageChanged(int index) {
    if (index == _currentPageIndex) return;
    
    // 设置动画状态为进行中
    setState(() {
      _isAnimating = true;
      _currentPageIndex = index;
    });
    
    // 动画完成后重置状态
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _isAnimating = false;
        });
      }
    });
  }

  Widget _getCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return homePageView();
      case 1:
        return modsPageView();
      case 2:
        return modCollectionsPageView();
      case 3:
        return steamWorkshopView();
      case 4:
        return settingsPageView();
      default:
        return homePageView();
    }
  }

  /// 获取带动画的当前页面
  Widget _getCurrentPageWithAnimation() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: Container(
        key: ValueKey(_currentPageIndex), // 确保页面切换时触发动画
        child: _getCurrentPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: createAppLayout(
        currentPageIndex: _currentPageIndex,
        onPageChanged: _onPageChanged,
        child: _getCurrentPageWithAnimation(),
      ),
    );
  }
}
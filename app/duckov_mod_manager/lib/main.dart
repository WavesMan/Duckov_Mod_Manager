import 'package:flutter/material.dart';
import 'components/layout.dart';
import 'page/home.dart';
import 'page/mod_page.dart';
import 'page/mod_collections_page.dart';
import 'page/steam_workshop_page.dart';
import 'page/setting_page.dart';
import 'services/preload_manager.dart';

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
      home: PreloadWidget(
        child: const MainAppLayout(),
      ),
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

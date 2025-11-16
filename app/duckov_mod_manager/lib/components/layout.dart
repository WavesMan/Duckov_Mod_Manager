// layout.dart
/// 应用程序主布局组件

import 'package:flutter/material.dart';
import '../services/route_service.dart';
import '../services/theme_manager.dart';

class AppLayout extends StatefulWidget {
  final int currentPageIndex;
  final Function(int) onPageChanged;
  final Widget child;

  const AppLayout({
    Key? key,
    required this.currentPageIndex,
    required this.onPageChanged,
    required this.child,
  }) : super(key: key);

  @override
  _AppLayoutState createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  bool _sidebarExpanded = true;
  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // 侧边栏
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: _sidebarExpanded ? 250 : 80,
          child: Container(
            color: ThemeManager.getThemeColor('background'),
            child: Column(
              children: [
                // 应用标题和切换按钮
                Container(
                  height: 60,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      if (_sidebarExpanded)
                        Expanded(
                          child: headingText('Duckov Mod Manager', level: 3),
                        ),
                      IconButton(
                        icon: Icon(_sidebarExpanded ? Icons.chevron_left : Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _sidebarExpanded = !_sidebarExpanded;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                Divider(height: 1),
                // 导航项
                Expanded(
                  child: ListView.builder(
                    itemCount: navigationItems.length,
                    itemBuilder: (context, index) {
                      final item = navigationItems[index];
                      return ListTile(
                        leading: Icon(item.icon),
                        title: _sidebarExpanded ? Text(item.title) : null,
                        // 导航项文本颜色
                        textColor: widget.currentPageIndex == index
                            ? ThemeManager.getThemeColor('primary')
                            : ThemeManager.getThemeColor('text_secondary'),
                        selected: widget.currentPageIndex == index,
                        onTap: () {
                          widget.onPageChanged(index);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        // 主内容区
        Expanded(
          child: Container(
            color: ThemeManager.getThemeColor('background'),
            child: Padding(
              padding: EdgeInsets.all(24),
              child: widget.child,
            ),
          ),
        ),
      ],
    );
  }
}

/// 便捷函数 - 创建应用布局
Widget createAppLayout({
  required int currentPageIndex,
  required Function(int) onPageChanged,
  required Widget child,
}) {
  return AppLayout(
    currentPageIndex: currentPageIndex,
    onPageChanged: onPageChanged,
    child: child,
  );
}
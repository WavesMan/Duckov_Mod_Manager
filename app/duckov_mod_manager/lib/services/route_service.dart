// route_service.dart
/// 路由服务 - 定义应用路由和导航项

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class AppRoutes {
  static const String home = '/home';
  static const String mods = '/mods';
  static const String modOrder = '/mod-order';
  static const String modCollections = '/mod-collections';
  static const String steamWorkshop = '/steam-workshop';
  static const String settings = '/settings';
  static const String update = '/update';
}

class NavigationItem {
  final String title;
  final IconData icon;
  final String route;

  NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

final List<NavigationItem> navigationItems = [
  NavigationItem(title: '主页', icon: Icons.home, route: AppRoutes.home),
  NavigationItem(title: '模组管理', icon: Icons.apps, route: AppRoutes.mods),
  NavigationItem(title: '加载顺序', icon: Icons.format_list_numbered, route: AppRoutes.modOrder),
  // NavigationItem(title: 'Mod合集 BETA', icon: Icons.collections, route: AppRoutes.modCollections),
  NavigationItem(title: '创意工坊', icon: Icons.workspaces, route: AppRoutes.steamWorkshop),
  NavigationItem(title: '设置', icon: Icons.settings, route: AppRoutes.settings),
];

class RouteService {
  static final RouteService instance = RouteService._();
  RouteService._();

  final ValueNotifier<String> _currentRoute = ValueNotifier<String>(AppRoutes.home);
  ValueListenable<String> get currentRoute => _currentRoute;

  void goTo(String route) {
    _currentRoute.value = route;
  }

  void goToIndex(int index) {
    if (index < 0 || index >= navigationItems.length) return;
    _currentRoute.value = navigationItems[index].route;
  }

  int routeToIndex(String route) {
    final idx = navigationItems.indexWhere((e) => e.route == route);
    return idx >= 0 ? idx : 0;
  }
}
// route_service.dart
/// 路由服务 - 定义应用路由和导航项

import 'package:flutter/material.dart';

class AppRoutes {
  static const String home = '/home';
  static const String mods = '/mods';
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
  NavigationItem(title: 'Mod合集', icon: Icons.collections, route: AppRoutes.modCollections),
  NavigationItem(title: '创意工坊', icon: Icons.workspaces, route: AppRoutes.steamWorkshop),
  NavigationItem(title: '设置', icon: Icons.settings, route: AppRoutes.settings),
];
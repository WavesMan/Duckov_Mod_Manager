// theme_manager.dart
/// 主题管理服务

import 'package:flutter/material.dart';

class ThemeManager {
  /// 获取主题颜色
  static Map<String, Color> getThemeColors() {
    return {
      'primary': Color(0xFF1976D2),
      'on_primary': Colors.white,
      'secondary': Color(0xFF424242),
      'on_secondary': Colors.white,
      'background': Color(0xFFFAFAFA),
      'on_background': Color(0xFF212121),
      'surface': Colors.white,
      'on_surface': Color(0xFF212121),
      'error': Color(0xFFD32F2F),
      'on_error': Colors.white,
      'text_primary': Color(0xFF212121),
      'text_secondary': Color(0xFF757575),
      'sidebar_background': Color(0xFFF5F5F5),
    };
  }

  /// 获取主题颜色
  static Color getThemeColor(String colorName) {
    final colors = getThemeColors();
    return colors[colorName] ?? Colors.black;
  }

  /// 创建标题文本样式
  static TextStyle headingTextStyle({int level = 1, Color? color}) {
    final colors = getThemeColors();
    final baseColor = color ?? colors['text_primary']!;
    
    switch (level) {
      case 1:
        return TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: baseColor,
          fontFamily: 'MiSans',
        );
      case 2:
        return TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: baseColor,
          fontFamily: 'MiSans',
        );
      case 3:
        return TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: baseColor,
          fontFamily: 'MiSans',
        );
      case 4:
        return TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: baseColor,
          fontFamily: 'MiSans',
        );
      default:
        return TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: baseColor,
          fontFamily: 'MiSans',
        );
    }
  }

  /// 创建正文文本样式
  static TextStyle bodyTextStyle({double size = 16, Color? color}) {
    final colors = getThemeColors();
    final baseColor = color ?? colors['text_secondary']!;
    
    return TextStyle(
      fontSize: size,
      fontWeight: FontWeight.normal,
      color: baseColor,
      fontFamily: 'MiSans',
    );
  }
}

/// 便捷函数 - 创建标题文本
Widget headingText(String text, {int level = 1, Color? color}) {
  return Text(
    text,
    style: ThemeManager.headingTextStyle(level: level, color: color),
  );
}

/// 便捷函数 - 创建正文文本
Widget bodyText(String text, {double size = 16, Color? color}) {
  return Text(
    text,
    style: ThemeManager.bodyTextStyle(size: size, color: color),
  );
}
// theme_manager.dart
/// 旧版主题管理服务（在原基础上增加多主题支持）
///
/// 要求：
/// - 保持所有旧 API 不变：
///   - ThemeManager.getThemeColors()
///   - ThemeManager.getThemeColor(String)
///   - ThemeManager.headingTextStyle(...)
///   - ThemeManager.bodyTextStyle(...)
///   - 全局函数 headingText(...) / bodyText(...)
/// - 新增 light / dark / system 模式，默认 system 跟随系统明暗。

import 'package:flutter/material.dart';

/// 新增：主题模式枚举
enum AppThemeMode {
  light,
  dark,
  system,
}

class ThemeManager {
  /// 新增：当前主题模式（默认跟随系统）
  static AppThemeMode _currentMode = AppThemeMode.system;

  /// 可选：对外只读，方便外部知道当前模式
  static AppThemeMode get currentMode => _currentMode;

  /// 新增：设置主题模式（调用方可在设置页/启动处使用）
  static void setThemeMode(AppThemeMode mode) {
    _currentMode = mode;
    for (final l in _listeners.toList()) {
      try {
        l();
      } catch (_) {}
    }
  }

  static final Set<VoidCallback> _listeners = <VoidCallback>{};
  static void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }
  static void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  /// 内部：根据 _currentMode 和系统亮度得到最终模式
  static AppThemeMode _effectiveMode() {
    if (_currentMode != AppThemeMode.system) {
      return _currentMode;
    }
    final brightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    return brightness == Brightness.dark
        ? AppThemeMode.dark
        : AppThemeMode.light;
  }

  /// 原来的"唯一主题"抽成亮色配置，保持完全不变
  static const Map<String, Color> _lightColors = {
    'primary': Color(0xFF1976D2),
    'on_primary': Colors.white,
    'secondary': Color(0xFF424242),
    'on_secondary': Colors.white,
    'background': Color(0xFFFAFAFA),
    'on_background': Color(0xFF212121),
    'surface': Colors.white,
    'on_surface': Color(0xFF212121),
    'success': Color(0xFF43A047),
    'error': Color(0xFFD32F2F),
    'on_error': Colors.white,
    'text_primary': Color(0xFF212121),
    'text_secondary': Color(0xFF757575),
    'sidebar_background': Color(0xFFF5F5F5),
    'edit_color': Color(0xFF2D8BE3),
  };

  /// 新增：暗色模式配色
  static const Map<String, Color> _darkColors = {
    'primary': Color(0xFF64B5F6),
    'on_primary': Colors.black,
    'secondary': Color(0xFF9E9E9E),
    'on_secondary': Colors.black,
    'background': Color(0xFF1E1E1E),
    'on_background': Color(0xFFE0E0E0),
    'surface': Color(0xFF2D2D2D),
    'on_surface': Color(0xFFE0E0E0),
    'success': Color(0xFF2E7D32),
    'error': Color(0xFFD32F2F),
    'on_error': Colors.black,
    'text_primary': Color(0xFFE0E0E0),
    'text_secondary': Color(0xFFBDBDBD),
    'sidebar_background': Color(0xFF262626),
    'edit_color': Color(0xFF2D8BE3),
  };

  /// 旧 API：获取主题颜色 Map
  /// 实现改为"按当前模式选择 light/dark"，但签名完全不变
  static Map<String, Color> getThemeColors() {
    switch (_effectiveMode()) {
      case AppThemeMode.light:
        return _lightColors;
      case AppThemeMode.dark:
        return _darkColors;
      case AppThemeMode.system:
        // 实际不会走到这里（_effectiveMode 已转换成 light/dark）
        return _lightColors;
    }
  }

  /// 旧 API：获取单个颜色
  static Color getThemeColor(String colorName) {
    final colors = getThemeColors();
    return colors[colorName] ?? Colors.black;
  }

  /// 旧 API：创建标题文本样式
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

  /// 旧 API：创建正文文本样式
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

/// 旧 API：便捷函数 - 创建标题文本
Widget headingText(String text, {int level = 1, Color? color}) {
  return Text(
    text,
    style: ThemeManager.headingTextStyle(level: level, color: color),
  );
}

/// 旧 API：便捷函数 - 创建正文文本
Widget bodyText(String text, {double size = 16, Color? color}) {
  return Text(
    text,
    style: ThemeManager.bodyTextStyle(size: size, color: color),
  );
}
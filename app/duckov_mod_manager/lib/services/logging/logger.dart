import 'dart:convert';
import '../config_manager.dart';

enum LogLevel { debug, info, warn, error }

class Log {
  static LogLevel _level = LogLevel.info;
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    final v = configManager.get('log_level', defaultValue: 'info');
    switch (('$v').toLowerCase()) {
      case 'debug':
        _level = LogLevel.debug;
        break;
      case 'warn':
        _level = LogLevel.warn;
        break;
      case 'error':
        _level = LogLevel.error;
        break;
      default:
        _level = LogLevel.info;
    }
    _initialized = true;
  }

  static bool _enabled(LogLevel l) {
    _init();
    return l.index >= _level.index;
  }

  static void _out(LogLevel level, String module, String message, {Map<String, dynamic>? metadata}) {
    if (!_enabled(level)) return;
    final ts = DateTime.now().toIso8601String();
    final lvl = level.name.toUpperCase();
    final meta = metadata == null ? '' : ' | metadata=' + jsonEncode(metadata);
    print('['+ts+'] ['+lvl+'] ['+module+'] '+message+meta);
  }

  static void debug(String module, String message, {Map<String, dynamic>? metadata}) => _out(LogLevel.debug, module, message, metadata: metadata);
  static void info(String module, String message, {Map<String, dynamic>? metadata}) => _out(LogLevel.info, module, message, metadata: metadata);
  static void warn(String module, String message, {Map<String, dynamic>? metadata}) => _out(LogLevel.warn, module, message, metadata: metadata);
  static void error(String module, String message, {Map<String, dynamic>? metadata}) => _out(LogLevel.error, module, message, metadata: metadata);
}
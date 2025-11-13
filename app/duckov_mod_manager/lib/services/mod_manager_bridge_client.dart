/// ModManagerBridge 客户端 - 与游戏内Bridge API通信
/// 支持TCP JSON-RPC风格的实时模组管理

import 'dart:io';
import 'dart:convert';
import 'dart:async';

class ModManagerBridgeClient {
  static const String _host = '127.0.0.1';
  static const int _port = 38274;
  static const Duration _timeout = Duration(seconds: 5);
  
  Socket? _socket;
  bool _isConnected = false;
  final StreamController<Map<String, dynamic>> _responseController = StreamController.broadcast();
  
  /// 连接状态变更监听
  Stream<bool> get connectionStatusStream {
    if (_socket == null) {
      return Stream.value(false);
    }
    return _socket!.handleError((error) {
      print('[ModManagerBridge] 连接错误: $error');
      _isConnected = false;
    }).map((event) => _isConnected);
  }
  
  /// 响应数据流
  Stream<Map<String, dynamic>> get responseStream => _responseController.stream;
  
  /// 检查连接状态
  Future<bool> get isConnected async {
    if (_socket == null || _isConnected == false) {
      try {
        await connect();
      } catch (e) {
        return false;
      }
    }
    return _isConnected;
  }
  
  /// 建立TCP连接
  Future<void> connect() async {
    try {
      _socket = await Socket.connect(_host, _port, timeout: _timeout);
      _isConnected = true;
      
      // 监听服务端响应
      _socket!.listen(
        (List<int> data) {
          final response = utf8.decode(data);
          print('[ModManagerBridge] 收到响应: $response');
          
          try {
            final jsonResponse = json.decode(response);
            if (jsonResponse is Map<String, dynamic>) {
              _responseController.add(jsonResponse);
            }
          } catch (e) {
            print('[ModManagerBridge] JSON解析错误: $e');
          }
        },
        onError: (error) {
          print('[ModManagerBridge] 监听错误: $error');
          _isConnected = false;
        },
        onDone: () {
          print('[ModManagerBridge] 连接已断开');
          _isConnected = false;
        },
      );
      
      print('[ModManagerBridge] 已连接到 ${_host}:${_port}');
    } catch (e) {
      print('[ModManagerBridge] 连接失败: $e');
      _isConnected = false;
      throw Exception('无法连接到 ModManagerBridge: $e');
    }
  }
  
  /// 断开连接
  void disconnect() {
    _socket?.close();
    _socket = null;
    _isConnected = false;
    print('[ModManagerBridge] 已断开连接');
  }
  
  /// 发送命令
  Future<Map<String, dynamic>> sendCommand(String command, [Map<String, dynamic>? parameters]) async {
    if (!await isConnected) {
      throw Exception('未连接到 ModManagerBridge');
    }
    
    final request = {
      'command': command,
      'parameters': parameters ?? {},
    };
    
    final requestJson = json.encode(request);
    final requestBytes = utf8.encode(requestJson);
    
    print('[ModManagerBridge] 发送命令: $requestJson');
    
    _socket!.add(requestBytes);
    _socket!.flush();
    
    // 等待响应（超时处理）
    return _waitForResponse().timeout(
      _timeout,
      onTimeout: () {
        throw Exception('命令超时');
      },
    );
  }
  
  /// 等待响应
  Future<Map<String, dynamic>> _waitForResponse() async {
    return await _responseController.stream.first;
  }
  
  /// 获取模组列表
  Future<List<BridgeModInfo>> getModList() async {
    try {
      final response = await sendCommand('get_mod_list');
      
      if (response['status'] == 'success') {
        final List<dynamic> data = response['data'] ?? [];
        return data.map((mod) => BridgeModInfo.fromJson(mod)).toList();
      } else {
        throw Exception('获取模组列表失败: ${response['message']}');
      }
    } catch (e) {
      print('[ModManagerBridge] getModList 错误: $e');
      return [];
    }
  }
  
  /// 获取模组详细信息
  Future<BridgeModInfo?> getModInfo(String modName) async {
    try {
      final response = await sendCommand('get_mod_info', {'ModName': modName});
      
      if (response['status'] == 'success') {
        final Map<String, dynamic> data = response['data'] ?? {};
        return BridgeModInfo.fromJson(data);
      } else {
        print('[ModManagerBridge] 获取模组信息失败: ${response['message']}');
        return null;
      }
    } catch (e) {
      print('[ModManagerBridge] getModInfo 错误: $e');
      return null;
    }
  }
  
  /// 启用模组
  Future<bool> enableMod(String modName) async {
    try {
      final response = await sendCommand('enable_mod', {'ModName': modName});
      
      if (response['status'] == 'success') {
        print('[ModManagerBridge] 模组 $modName 启用成功');
        return true;
      } else {
        print('[ModManagerBridge] 启用模组失败: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('[ModManagerBridge] enableMod 错误: $e');
      return false;
    }
  }
  
  /// 禁用模组
  Future<bool> disableMod(String modName) async {
    try {
      final response = await sendCommand('disable_mod', {'ModName': modName});
      
      if (response['status'] == 'success') {
        print('[ModManagerBridge] 模组 $modName 禁用成功');
        return true;
      } else {
        print('[ModManagerBridge] 禁用模组失败: ${response['message']}');
        return false;
      }
    } catch (e) {
      print('[ModManagerBridge] disableMod 错误: $e');
      return false;
    }
  }
  
  /// 批量操作模组状态
  Future<Map<String, bool>> batchToggleMods(List<String> modNames, bool enable) async {
    final results = <String, bool>{};
    for (final modName in modNames) {
      try {
        results[modName] = enable 
            ? await enableMod(modName) 
            : await disableMod(modName);
      } catch (e) {
        print('[ModManagerBridge] 批量操作模组 $modName 错误: $e');
        results[modName] = false;
      }
    }
    return results;
  }
  
  /// 重新加载所有模组
  Future<bool> reloadAllMods() async {
    try {
      final response = await sendCommand('reload_all_mods');
      return response['status'] == 'success';
    } catch (e) {
      print('[ModManagerBridge] reloadAllMods 错误: $e');
      return false;
    }
  }
  
  void dispose() {
    disconnect();
    _responseController.close();
  }
}

/// Bridge API 模组信息
class BridgeModInfo {
  final String name;
  final bool enabled;
  final String version;
  final String author;
  final String? description;
  final String? id;
  
  BridgeModInfo({
    required this.name,
    required this.enabled,
    required this.version,
    required this.author,
    this.description,
    this.id,
  });
  
  factory BridgeModInfo.fromJson(Map<String, dynamic> json) {
    return BridgeModInfo(
      name: json['name'] ?? '',
      enabled: json['enabled'] ?? false,
      version: json['version'] ?? '1.0.0',
      author: json['author'] ?? 'Unknown',
      description: json['description'],
      id: json['id'],
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'enabled': enabled,
      'version': version,
      'author': author,
      'description': description,
      'id': id,
    };
  }
}

/// 桥接模组信息扩展 - 转换为标准 ModInfo 格式
extension BridgeModInfoExtension on BridgeModInfo {
  /// 转换为标准 ModInfo 格式以便与现有系统兼容
  Map<String, dynamic> toStandardModInfo() {
    return {
      'id': id ?? name,
      'name': name,
      'displayName': name,
      'description': description ?? '',
      'version': version,
      'enabled': enabled,
      'size': 'N/A',
      'path': '',
      'isBridgeMod': true,
    };
  }
}

// 创建全局Bridge客户端实例
final modManagerBridgeClient = ModManagerBridgeClient();
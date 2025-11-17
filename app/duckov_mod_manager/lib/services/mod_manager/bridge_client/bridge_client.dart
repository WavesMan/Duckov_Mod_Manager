import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

enum BridgeStatus { disconnected, connecting, connected, error }

class BridgeClient {
  final String host;
  final int port;
  final Duration connectTimeout;
  final Duration requestTimeout;

  WebSocketChannel? _channel;
  StreamController<dynamic>? _incoming;
  StreamSubscription? _subscription;
  BridgeStatus _status = BridgeStatus.disconnected;
  bool _connecting = false;
  bool _sending = false;
  Completer<void>? _sendDone;

  BridgeClient({
    this.host = '127.0.0.1',
    this.port = 9001,
    this.connectTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 30),
  });

  BridgeStatus get status => _status;
  bool get isConnected => _status == BridgeStatus.connected;
  Uri get uri => Uri.parse('ws://$host:$port/');

  Future<bool> connect() async {
    if (_connecting || isConnected) return isConnected;
    _connecting = true;
    _status = BridgeStatus.connecting;
    print('[bridge_client] connecting to '+uri.toString());
    try {
      final ws = await WebSocket.connect(
        uri.toString(),
        headers: {
          'Origin': 'http://localhost',
        },
        compression: const CompressionOptions(enabled: false),
      );
      ws.pingInterval = null;
      _channel = IOWebSocketChannel(ws);
      _incoming = StreamController<dynamic>.broadcast();
      _subscription = _channel!.stream.listen(
        (event) {
          _incoming?.add(event);
        },
        onError: (e) {
          print('[bridge_client] stream error: '+e.toString());
        },
        onDone: () {
          _status = BridgeStatus.disconnected;
        },
      );
      _status = BridgeStatus.connected;
      _connecting = false;
      print('[bridge_client] connected');
      return true;
    } catch (e) {
      _status = BridgeStatus.error;
      _connecting = false;
      print('[bridge_client] connect error: '+e.toString());
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      await _channel?.sink.close();
      _channel = null;
      await _subscription?.cancel();
      _subscription = null;
      await _incoming?.close();
      _incoming = null;
      _status = BridgeStatus.disconnected;
      print('[bridge_client] disconnected');
    } catch (e) {
      _status = BridgeStatus.error;
      print('[bridge_client] disconnect error: '+e.toString());
    }
  }

  Future<Map<String, dynamic>?> _send(String action, dynamic data) async {
    if (_channel == null) {
      final ok = await connect();
      if (!ok) return null;
    }
    while (_sending) {
      if (_sendDone != null) {
        try {
          await _sendDone!.future;
        } catch (_) {}
      } else {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
    _sending = true;
    _sendDone = Completer<void>();
    final payload = {
      'action': action,
      'data': _normalizeData(data),
    };
    final jsonStr = jsonEncode(payload);
    print('[bridge_client] -> '+jsonStr);
    try {
      _channel!.sink.add(jsonStr);
      final parsed = await _incoming!.stream
          .map(_tryParseToMap)
          .where((m) => m != null && m!.containsKey('success'))
          .map((m) => m!)
          .first
          .timeout(requestTimeout);
      print('[bridge_client] <- '+jsonEncode(parsed));
      return parsed;
    } catch (e) {
      print('[bridge_client] request error: '+e.toString());
      return null;
    } finally {
      _sending = false;
      if (_sendDone != null && !_sendDone!.isCompleted) {
        _sendDone!.complete();
      }
    }
  }

  String _normalizeData(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    return jsonEncode(data);
  }

  Map<String, dynamic>? _tryParseToMap(dynamic raw) {
    try {
      final text = raw is String ? raw : utf8.decode(raw as List<int>);
      final obj = jsonDecode(text);
      if (obj is Map<String, dynamic>) return obj;
    } catch (_) {}
    return null;
  }

  Future<List<Map<String, dynamic>>> getModList() async {
    final resp = await _send('get_mod_list', '');
    if (resp == null || resp['success'] != true) return [];
    final ds = resp['data'];
    try {
      final list = jsonDecode(ds is String ? ds : jsonEncode(ds));
      if (list is List) {
        return List<Map<String, dynamic>>.from(list);
      }
    } catch (_) {}
    return [];
  }

  Future<bool> activateMod(String modName) async {
    final resp = await _send('activate_mod', modName);
    return resp != null && resp['success'] == true;
  }

  Future<bool> deactivateMod(String modName) async {
    final resp = await _send('deactivate_mod', modName);
    return resp != null && resp['success'] == true;
  }

  Future<bool> activateMods(List<String> modNames) async {
    final resp = await _send('activate_mods', modNames);
    return resp != null && resp['success'] == true;
  }

  Future<bool> deactivateMods(List<String> modNames) async {
    final resp = await _send('deactivate_mods', modNames);
    return resp != null && resp['success'] == true;
  }

  Future<bool> rescanMods() async {
    final resp = await _send('rescan_mods', '');
    return resp != null && resp['success'] == true;
  }

  Future<bool> setPriority(String modName, int priority) async {
    final resp = await _send('set_priority', jsonEncode({'name': modName, 'priority': priority}));
    return resp != null && resp['success'] == true;
  }

  Future<bool> reorderMods(List<String> orderNames) async {
    final resp = await _send('reorder_mods', jsonEncode(orderNames));
    return resp != null && resp['success'] == true;
  }

  Future<bool> applyOrderAndRescan(List<String> orderNames) async {
    final resp = await _send('apply_order_and_rescan', jsonEncode(orderNames));
    return resp != null && resp['success'] == true;
  }

  Future<void> dispose() async {
    await disconnect();
  }
}

final bridgeClient = BridgeClient();
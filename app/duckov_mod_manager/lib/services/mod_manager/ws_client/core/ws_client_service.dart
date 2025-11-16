import 'dart:async';
import 'package:duckov_mod_manager/services/mod_manager/bridge_client/bridge_client.dart';
import 'package:duckov_mod_manager/services/logging/logger.dart';
import 'package:duckov_mod_manager/services/mod_manager.dart';
import 'package:duckov_mod_manager/services/mod_manager/ws_client/ops/change_queue.dart';

class WsClientService {
  static final WsClientService instance = WsClientService._();
  WsClientService._();

  final BridgeClient _client = bridgeClient;
  final ChangeQueue _queue = ChangeQueue();
  final StreamController<String> _status = StreamController<String>.broadcast();
  bool _running = false;
  bool _connecting = false;
  bool _suppress = false;
  int _backoffSec = 1;

  Stream<String> get statusStream => _status.stream;
  bool get isRunning => _running;
  bool get isConnected => _client.isConnected;

  Future<void> start() async {
    if (_running) return;
    _running = true;
    unawaited(_loop());
  }

  Future<void> stop() async {
    _running = false;
    await _client.disconnect();
  }

  void applyLocalChange(String modId, bool enabled) {
    if (_suppress) return;
    _queue.apply(modId, enabled);
  }

  void applyBatch(List<String> enableIds, List<String> disableIds) {
    if (_suppress) return;
    _queue.applyBatch(enableIds, disableIds);
  }

  Future<void> _loop() async {
    while (_running) {
      if (!_client.isConnected) {
        if (_connecting) {
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }
        _connecting = true;
        _status.add('connecting');
        Log.info('WsClientService', 'connecting');
        final ok = await _client.connect();
        _connecting = false;
        if (!ok) {
          _status.add('disconnected');
          Log.warn('WsClientService', 'connect failed', metadata: {'backoff_sec': _backoffSec});
          await Future.delayed(Duration(seconds: _backoffSec));
          _backoffSec = (_backoffSec * 2).clamp(1, 15);
          continue;
        }
        _backoffSec = 1;
        _status.add('connected');
        Log.info('WsClientService', 'connected');
        await _initialSync();
      }
      await _flushQueue();
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _initialSync() async {
    try {
      _status.add('syncing');
      Log.info('WsClientService', 'initial sync start');
      final localMods = await modManager.getDownloadedMods();
      final enableNames = <String>[];
      final disableNames = <String>[];
      for (final m in localMods) {
        final e = await modManager.isModEnabled(m.id);
        if (e) {
          enableNames.add(m.name);
        } else {
          disableNames.add(m.name);
        }
      }
      if (enableNames.isNotEmpty) {
        for (var i = 0; i < enableNames.length; i += 10) {
          final chunk = enableNames.sublist(i, (i + 10).clamp(0, enableNames.length));
          final ok = await _client.activateMods(chunk);
          Log.info('WsClientService', 'activate batch', metadata: {'count': chunk.length, 'success': ok});
        }
      }
      if (disableNames.isNotEmpty) {
        for (var i = 0; i < disableNames.length; i += 10) {
          final chunk = disableNames.sublist(i, (i + 10).clamp(0, disableNames.length));
          final ok = await _client.deactivateMods(chunk);
          Log.info('WsClientService', 'deactivate batch', metadata: {'count': chunk.length, 'success': ok});
        }
      }
      await _reconcileFromServer();
      _status.add('synced');
      Log.info('WsClientService', 'initial sync done');
    } catch (e) {
      Log.error('WsClientService', 'initial sync error', metadata: {'error': '$e'});
    }
  }

  Future<void> _flushQueue() async {
    if (_queue.isEmpty) return;
    if (!_client.isConnected) return;
    final idMap = await _buildIdNameMap();
    final batch = _queue.take(10);
    final enableNames = batch.enable.map((id) => idMap[id] ?? id).toList();
    final disableNames = batch.disable.map((id) => idMap[id] ?? id).toList();
    if (enableNames.isNotEmpty) {
      final ok = await _client.activateMods(enableNames);
      Log.info('WsClientService', 'flush enable', metadata: {'count': enableNames.length, 'success': ok});
    }
    if (disableNames.isNotEmpty) {
      final ok = await _client.deactivateMods(disableNames);
      Log.info('WsClientService', 'flush disable', metadata: {'count': disableNames.length, 'success': ok});
    }
    await _reconcileFromServer();
  }

  Future<void> _reconcileFromServer() async {
    try {
      final list = await _client.getModList();
      final idMap = await _buildIdNameMap();
      final enabledIds = <String>{};
      final disabledIds = <String>{};
      for (final item in list) {
        final nameRaw = item['name'] ?? '';
        final name = '$nameRaw';
        final en = item['enabled'] ?? item['active'] ?? item['isActive'] ?? false;
        if (name.isEmpty) continue;
        final id = idMap.entries.firstWhere(
          (e) => e.value == name,
          orElse: () => const MapEntry<String, String>('', ''),
        ).key;
        if (id.isEmpty) continue;
        if (en == true) {
          enabledIds.add(id);
        } else {
          disabledIds.add(id);
        }
      }
      _suppress = true;
      for (final id in enabledIds) {
        await modManager.enableMod(id);
      }
      for (final id in disabledIds) {
        await modManager.disableMod(id);
      }
      _suppress = false;
      Log.info('WsClientService', 'reconcile', metadata: {'enabled': enabledIds.length, 'disabled': disabledIds.length});
    } catch (e) {
      Log.error('WsClientService', 'reconcile error', metadata: {'error': '$e'});
    }
  }

  Future<Map<String, String>> _buildIdNameMap() async {
    final map = <String, String>{};
    try {
      final wsMods = await modManager.getDownloadedMods();
      for (final m in wsMods) {
        map[m.id] = m.name;
      }
      final localMods = await modManager.getLocalMods();
      for (final m in localMods) {
        map[m.id] = m.name;
      }
    } catch (e) {
      Log.warn('WsClientService', 'build id->name map error', metadata: {'error': '$e'});
    }
    return map;
  }
}
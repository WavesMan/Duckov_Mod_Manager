import 'dart:async';
import 'package:flutter/material.dart';
import '../services/theme_manager.dart';
import '../services/mod_manager/bridge_client/bridge_client.dart';
import '../services/mod_manager/ws_client/core/ws_client_service.dart';

class ModOrderPage extends StatefulWidget {
  const ModOrderPage({super.key});
  @override
  State<ModOrderPage> createState() => _ModOrderPageState();
}

class _ModOrderPageState extends State<ModOrderPage> {
  List<Map<String, dynamic>> _mods = [];
  bool _loading = true;
  bool _saving = false;
  StreamSubscription<String>? _wsSub;
  Timer? _loadGuard;

  @override
  void initState() {
    super.initState();
    WsClientService.instance.start();
    _wsSub = WsClientService.instance.statusStream.listen((s) {
      if (!mounted) return;
      if (s == 'connected' || s == 'synced') {
        _loadMods();
      }
      if (s == 'disconnected') {
        setState(() {
          _loading = false;
        });
      }
    });
    _loadGuard = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _loading = false;
        });
      }
    });
    _loadMods();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _loadGuard?.cancel();
    super.dispose();
  }

  Future<void> _loadMods() async {
    if (!mounted) return;
    setState(() => _loading = true);
    _loadGuard?.cancel();
    _loadGuard = Timer(const Duration(seconds: 10), () {
      if (!mounted) return;
      if (_loading) {
        setState(() {
          _loading = false;
        });
      }
    });
    try {
      final list = await bridgeClient.getModList();
      list.sort((a, b) => (a['priority'] ?? 0).compareTo(b['priority'] ?? 0));
      // 确保在异步操作后仍然mounted
      if (mounted) {
        setState(() {
          _mods = List.from(list); // 创建新的列表实例避免引用问题
          _loading = false;
        });
      }
      _loadGuard?.cancel();
    } catch (e) {
      // 处理可能的异常情况
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
      _loadGuard?.cancel();
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;
    
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      
      // 创建新列表避免直接修改原列表
      final newMods = List<Map<String, dynamic>>.from(_mods);
      final item = newMods.removeAt(oldIndex);
      newMods.insert(newIndex, item);
      
      // 更新优先级
      for (var i = 0; i < newMods.length; i++) {
        newMods[i] = Map<String, dynamic>.from(newMods[i]);
        newMods[i]['priority'] = i;
      }
      
      _mods = newMods;
    });
  }

  List<String> _orderNames() => _mods.map((m) => '${m['name']}').toList();

  Future<void> _saveOrder() async {
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final ok = await bridgeClient.reorderMods(_orderNames());
      if (mounted) {
        setState(() => _saving = false);
        if (ok) await _loadMods();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _applyOrderAndRescan() async {
    if (!mounted) return;
    setState(() => _saving = true);
    try {
      final ok = await bridgeClient.applyOrderAndRescan(_orderNames());
      if (mounted) {
        setState(() => _saving = false);
        if (ok) await _loadMods();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final surface = ThemeManager.getThemeColor('surface');
    final textPrimary = ThemeManager.getThemeColor('text_primary');

    if (_loading) {
      return Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: surface,
          title: Text('模组加载顺序', style: TextStyle(color: textPrimary)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        title: Text('模组加载顺序', style: TextStyle(color: textPrimary)),
        actions: [
          IconButton(
            onPressed: _loadMods, 
            icon: const Icon(Icons.refresh)
          ),
          TextButton(
            onPressed: _saving ? null : _saveOrder, 
            child: const Text('保存排序')
          ),
          TextButton(
            onPressed: _saving ? null : _applyOrderAndRescan, 
            child: const Text('应用并重扫')
          ),
        ],
      ),
      body: (_mods.length >= 2)
          ? ReorderableListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _mods.length,
              buildDefaultDragHandles: true,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                return _buildModListItem(index);
              },
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _mods.length,
              itemBuilder: (context, index) {
                return _buildModListItem(index);
              },
            ),
    );
  }

  Widget _buildModListItem(int index) {
    final m = _mods[index];
    final name = '${m['name']}';
    final display = '${m['displayName'] ?? name}';
    final active = (m['isActive'] ?? m['enabled'] ?? false) == true;
    final priority = m['priority'] ?? index;
    final isSteam = (m['isSteamItem'] ?? false) == true;
    final pubId = m['publishedFileId']?.toString() ?? '';
    final path = '${m['path'] ?? ''}';
    final uniqueKey = isSteam && pubId.isNotEmpty ? 'steam:$pubId' : (path.isNotEmpty ? '$name|$path' : name);
    return SizedBox(
      key: ValueKey(uniqueKey),
      child: ListTile(
        leading: Icon(
          active ? Icons.check_circle : Icons.radio_button_unchecked,
          color: active ? Colors.green : Colors.grey,
        ),
        title: Text(display, style: TextStyle(color: ThemeManager.getThemeColor('text_primary'))),
        subtitle: Text('优先级: $priority', style: TextStyle(color: ThemeManager.getThemeColor('text_primary'))),
        trailing: const Icon(Icons.drag_indicator),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        dense: true,
      ),
    );
  }
}

Widget modOrderPageView() {
  return const ModOrderPage();
}
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart';
import '../mod_manager.dart';
import 'mod_collection.dart';

/// 合集合管理服务类 - 负责本地JSON持久化和事件流管理
class CollectionService {
  static const String _fileName = 'collections.json';
  final BehaviorSubject<List<ModCollection>> _controller = 
      BehaviorSubject<List<ModCollection>>();

  /// 外部只读流，页面用StreamBuilder监听
  Stream<List<ModCollection>> get collections$ => _controller.stream;

  /// 当前内存快照
  List<ModCollection> get _collections => _controller.valueOrNull ?? [];

  /// 初始化服务，加载保存的合集数据
  Future<void> init() async {
    try {
      final file = await _getFile();
      if (await file.exists()) {
        final raw = await file.readAsString();
        final list = (json.decode(raw) as List)
            .map((e) => ModCollection.fromJson(e))
            .toList();
        _controller.add(List.unmodifiable(list));
        print('[CollectionService] 成功加载 ${list.length} 个合集');
      } else {
        _controller.add(const []);
      }
    } catch (e) {
      _controller.addError(e);
      _controller.add(const []); // 出错时返回空列表作为回退
    }
  }

  /// 添加新合集
  Future<void> add(ModCollection collection) async {
    try {
      final updatedCollections = [..._collections, collection];
      await _save(updatedCollections);
    } catch (e) {
      rethrow;
    }
  }

  /// 删除合集
  Future<void> remove(String id) async {
    try {
      final updatedCollections = _collections.where((e) => e.id != id).toList();
      await _save(updatedCollections);
    } catch (e) {
      rethrow;
    }
  }

  /// 更新合集
  Future<void> update(ModCollection collection) async {
    try {
      final updatedCollections = _collections
          .map((e) => e.id == collection.id ? collection : e)
          .toList();
      await _save(updatedCollections);
    } catch (e) {
      rethrow;
    }
  }

  /// 启用合集（包含互斥逻辑）
  Future<void> enableCollection(ModCollection target) async {
    try {
      final allMods = target.modIds;
      // 1) 找到需要禁用的（互斥）模组和冲突的合集
      final toDisable = <String>[];
      final conflictingCollections = <ModCollection>[];
      
      if (target.exclusive) {
        for (final c in _collections) {
          if (c.id == target.id) continue;
          if (c.exclusive) {
            conflictingCollections.add(c);
            toDisable.addAll(c.modIds);
          }
        }
      }
      
      // 2) 批量调用ModManager执行操作
      if (toDisable.isNotEmpty) {
        await modManager.batchDisableMods(toDisable);
      }
      
      await modManager.batchEnableMods(allMods);
    } catch (e) {
      rethrow;
    }
  }

  /// 禁用合集
  Future<void> disableCollection(ModCollection target) async {
    try {
      await modManager.batchDisableMods(target.modIds);
    } catch (e) {
      rethrow;
    }
  }

  /// 获取合集详情
  ModCollection? getById(String id) {
    try {
      return _collections.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 检查是否有冲突的互斥合集
  List<ModCollection> getConflictingCollections(ModCollection target) {
    if (!target.exclusive) return const [];
    
    return _collections.where((c) {
      return c.id != target.id && c.exclusive;
    }).toList();
  }

  /// 获取合集中已安装的模组数量
  Future<int> getInstalledModCount(ModCollection collection) async {
    try {
      final wsMods = await modManager.getDownloadedMods();
      final localMods = await modManager.getLocalMods();
      final modIds = {
        ...wsMods.map((m) => m.id),
        ...localMods.map((m) => m.id),
      };
      return collection.modIds.where((id) => modIds.contains(id)).length;
    } catch (e) {
      return 0;
    }
  }

  /// 清除所有合集
  Future<void> clearAll() async {
    try {
      await _save(const []);
    } catch (e) {
      rethrow;
    }
  }

  /// 保存合集数据到文件
  Future<void> _save(List<ModCollection> list) async {
    try {
      final file = await _getFile();
      final jsonList = list.map((e) => e.toJson()).toList();
      final jsonString = json.encode(jsonList);
      await file.writeAsString(jsonString);
      _controller.add(List.unmodifiable(list));
    } catch (e) {
      rethrow;
    }
  }

  /// 获取配置文件路径
  Future<File> _getFile() async {
    final dir = await getApplicationSupportDirectory();
    final filePath = path.join(dir.path, _fileName);
    return File(filePath);
  }

  /// 销毁服务，释放资源
  void dispose() {
    _controller.close();
  }
}

/// 创建全局CollectionService实例
final collectionService = CollectionService();
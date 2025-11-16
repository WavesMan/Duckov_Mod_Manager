import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ModStateStore {
  DatabaseFactory? _factory;
  Database? _db;
  String? _dbPath;

  Future<void> init() async {
    sqfliteFfiInit();
    _factory = databaseFactoryFfi;
    final dir = await getApplicationSupportDirectory();
    _dbPath = path.join(dir.path, 'mod_state.db');
    _db = await _factory!.openDatabase(
      _dbPath!,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS mod_state ('
            'id TEXT PRIMARY KEY,'
            'enabled INTEGER NOT NULL,'
            'name TEXT,'
            'display_name TEXT,'
            'version TEXT,'
            'path TEXT,'
            'updated_at INTEGER NOT NULL'
            ')',
          );
        },
      ),
    );
    print('[ModStateStore] 数据库已打开: '+_dbPath!);
  }

  Future<void> dispose() async {
    await _db?.close();
    _db = null;
  }

  Future<bool?> getEnabled(String id) async {
    if (_db == null) return null;
    final rows = await _db!.query(
      'mod_state',
      columns: ['enabled'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final v = rows.first['enabled'] as int;
    return v == 1;
  }

  Future<Map<String, bool>> getEnabledMap(Iterable<String> ids) async {
    if (_db == null) return {};
    final list = ids.toList();
    if (list.isEmpty) return {};
    final placeholders = List.filled(list.length, '?').join(',');
    final rows = await _db!.rawQuery(
      'SELECT id, enabled FROM mod_state WHERE id IN ($placeholders)',
      list,
    );
    final map = <String, bool>{};
    for (final row in rows) {
      final id = row['id'] as String;
      final enabled = (row['enabled'] as int) == 1;
      map[id] = enabled;
    }
    return map;
  }

  Future<void> upsertState({
    required String id,
    required bool enabled,
    String? name,
    String? displayName,
    String? version,
    String? modPath,
  }) async {
    if (_db == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _db!.insert(
      'mod_state',
      {
        'id': id,
        'enabled': enabled ? 1 : 0,
        'name': name,
        'display_name': displayName,
        'version': version,
        'path': modPath,
        'updated_at': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    print('[ModStateStore] 状态写入: id='+id+', enabled='+(enabled ? '1' : '0')+', ts='+now.toString()+', path='+(modPath ?? ''));
  }

  Future<void> setEnabled(String id, bool enabled) async {
    await upsertState(id: id, enabled: enabled);
    print('[ModStateStore] 切换状态: id='+id+', enabled='+(enabled ? '1' : '0'));
  }
}
import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'local_mod_models.dart';
import 'mod_utils.dart';

class ModScanner {
  final void Function(String) log;
  ModScanner(this.log);

  Future<List<LocalModInfo>> scanWorkshopMods(String workshopPath) async {
    final result = <LocalModInfo>[];
    try {
      final directory = Directory(workshopPath);
      final entities = await directory.list().toList();
      final futures = <Future<LocalModInfo>>[];
      for (final e in entities) {
        if (e is Directory) {
          final modId = path.basename(e.path);
          if (RegExp(r'^\d+$').hasMatch(modId)) {
            futures.add(getModInfo(modId, e.path));
          }
        }
      }
      result.addAll(await Future.wait(futures));
    } catch (e) {
      log('获取已下载模组时出错: $e');
    }
    return result;
  }

  Future<LocalModInfo> getModInfo(String modId, String modPath) async {
    var info = LocalModInfo(
      id: modId,
      path: modPath,
      name: '模组 $modId',
      displayName: '模组 $modId',
      description: '暂无描述',
      version: '1.0.0',
      size: await getDirectorySize(modPath),
      author: null,
      previewImagePath: null,
    );

    final iniPath = path.join(modPath, 'info.ini');
    final iniFile = File(iniPath);
    if (await iniFile.exists()) {
      try {
        final content = await iniFile.readAsString();
        final lines = content.split('\n');
        for (final line in lines) {
          final t = line.trim();
          if (t.isNotEmpty && t.contains('=')) {
            final parts = t.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts[1].trim();
              switch (key) {
                case 'displayName':
                  info = info.copyWith(displayName: value);
                case 'name':
                  if (info.displayName == '模组 $modId') {
                    info = info.copyWith(displayName: value);
                  }
                  info = info.copyWith(name: value);
                case 'description':
                  info = info.copyWith(description: value);
                case 'version':
                  info = info.copyWith(version: value);
                case 'author':
                  info = info.copyWith(author: value);
              }
            }
          }
        }
      } catch (e) {
        log('读取info.ini时出错: $e');
      }
    }

    final preview = await findPreviewImage(modPath);
    if (preview != null) {
      info = info.copyWith(previewImagePath: preview);
    }

    try {
      final directory = Directory(modPath);
      final entities = await directory.list().toList();
      for (final e in entities) {
        if (e is File && e.path.endsWith('.json')) {
          try {
            final content = await e.readAsString();
            final data = json.decode(content);
            if (data is Map<String, dynamic>) {
              if (data.containsKey('name') && info.name == '模组 $modId') {
                info = info.copyWith(name: data['name']);
              }
              if (data.containsKey('version')) {
                info = info.copyWith(version: data['version']);
              }
              break;
            }
          } catch (_) {}
        }
      }
    } catch (_) {}

    return info;
  }

  Future<List<LocalModInfo>> scanLocalMods(String gameDirectory) async {
    final result = <LocalModInfo>[];
    final localModsPath = path.join(gameDirectory, 'Duckov_Data', 'Mods');
    final localDir = Directory(localModsPath);
    if (!await localDir.exists()) {
      return result;
    }
    try {
      final entities = await localDir.list().toList();
      final futures = <Future<LocalModInfo>>[];
      for (final e in entities) {
        if (e is Directory) {
          final modName = path.basename(e.path);
          futures.add(getLocalModInfo(modName, e.path));
        }
      }
      result.addAll(await Future.wait(futures));
    } catch (e) {
      log('获取本地模组时出错: $e');
    }
    return result;
  }

  Future<LocalModInfo> getLocalModInfo(String modName, String modPath) async {
    var info = LocalModInfo(
      id: modName,
      path: modPath,
      name: modName,
      displayName: modName,
      description: '本地模组 - 暂无描述',
      version: '1.0.0',
      size: await getDirectorySize(modPath),
      author: null,
      previewImagePath: null,
    );

    final iniPath = path.join(modPath, 'info.ini');
    final iniFile = File(iniPath);
    if (await iniFile.exists()) {
      try {
        final content = await iniFile.readAsString();
        final lines = content.split('\n');
        for (final line in lines) {
          final t = line.trim();
          if (t.isNotEmpty && t.contains('=')) {
            final parts = t.split('=');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts[1].trim();
              switch (key) {
                case 'displayName':
                  info = info.copyWith(displayName: value);
                case 'name':
                  if (info.displayName == modName) {
                    info = info.copyWith(displayName: value);
                  }
                  info = info.copyWith(name: value);
                case 'description':
                  info = info.copyWith(description: value);
                case 'version':
                  info = info.copyWith(version: value);
                case 'author':
                  info = info.copyWith(author: value);
              }
            }
          }
        }
      } catch (e) {
        log('读取本地模组info.ini时出错: $e');
      }
    }

    final preview = await findPreviewImage(modPath);
    if (preview != null) {
      info = info.copyWith(previewImagePath: preview);
    }
    return info;
  }
}
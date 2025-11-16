import 'dart:io';
import 'package:path/path.dart' as path;

class WorkshopPathDetector {
  bool isValidGameDirectoryPath(String p) {
    if (p.isEmpty) return false;
    final invalidChars = ['<', '>', '"', '|', '?', '*'];
    for (final c in invalidChars) {
      if (p.contains(c)) return false;
    }
    final isWindowsAbs = RegExp(r'^[A-Za-z]:[\\/]').hasMatch(p);
    final isUnixAbs = p.startsWith('/');
    if (!(isWindowsAbs || isUnixAbs)) return false;
    return true;
  }

  bool isValidGameDirectory(String gameDirectory) {
    try {
      final dir = Directory(gameDirectory);
      final entities = dir.listSync();
      final gameFiles = [
        'Escape from Duckov.exe',
        'duckov.exe',
        'game.exe',
        'Mods',
        'Saves',
        'Config',
        'Data',
        'duckov',
        'escape from duckov'
      ];
      for (final e in entities) {
        final name = e.path.split(Platform.pathSeparator).last.toLowerCase();
        for (final gf in gameFiles) {
          if (name.contains(gf.toLowerCase())) return true;
        }
      }
      if (gameDirectory.contains('steamapps') && gameDirectory.contains('common')) {
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  String? detectWorkshopPathFromGameDirectory(String gameDirectory) {
    try {
      final gameDir = Directory(gameDirectory);
      if (gameDirectory.contains('steamapps') && gameDirectory.contains('common')) {
        final steamappsDir = gameDir.parent.parent;
        return path.join(steamappsDir.path, 'workshop', 'content', '3167020');
      }
      final parentDir = gameDir.parent;
      return path.join(parentDir.path, 'workshop', 'content', '3167020');
    } catch (_) {
      return null;
    }
  }

  String getDefaultWorkshopPath() {
    final userProfile = Platform.environment['USERPROFILE'] ?? '';
    return path.join(userProfile, 'AppData', 'LocalLow', 'TeamSoda', 'Duckov', 'Mods');
  }
}
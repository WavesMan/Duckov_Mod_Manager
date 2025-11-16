import 'dart:io';
import 'package:path/path.dart' as path;

Future<String> getDirectorySize(String dirPath) async {
  var total = 0;
  try {
    final directory = Directory(dirPath);
    await for (final e in directory.list(recursive: true)) {
      if (e is File) {
        final stat = await e.stat();
        total += stat.size;
      }
    }
  } catch (_) {}
  return _formatSize(total);
}

String _formatSize(int bytes) {
  const kb = 1024;
  const mb = kb * 1024;
  const gb = mb * 1024;
  if (bytes < kb) return '$bytes B';
  if (bytes < mb) return '${(bytes / kb).toStringAsFixed(2)} KB';
  if (bytes < gb) return '${(bytes / mb).toStringAsFixed(2)} MB';
  return '${(bytes / gb).toStringAsFixed(2)} GB';
}

Future<String?> findPreviewImage(String modPath) async {
  try {
    final directory = Directory(modPath);
    final entities = await directory.list().toList();
    for (final e in entities) {
      if (e is File) {
        final name = path.basename(e.path).toLowerCase();
        if (name == 'preview.png' || name == 'preview.jpg' ||
            name == 'preview.jpeg' || name == 'preview.webp') {
          return e.path;
        }
      }
    }
  } catch (_) {}
  return null;
}
import 'package:flutter/material.dart';
import '../../../services/mod_manager.dart';
import '../../../services/theme_manager.dart';

void showModDetailsDialog(BuildContext context, LocalModInfo mod) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(mod.displayName),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('ID: ${mod.id}'),
            const SizedBox(height: 8),
            Text('名称: ${mod.name}'),
            const SizedBox(height: 8),
            Text('版本: ${mod.version}'),
            const SizedBox(height: 8),
            Text('大小: ${mod.size}'),
            const SizedBox(height: 8),
            Text('描述: ${mod.description}'),
            const SizedBox(height: 8),
            Text('路径: ${mod.path}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}
import 'package:flutter/material.dart';
import '../mod_collection.dart';

/// 互斥冲突确认对话框
class ExclusiveConflictDialog extends StatelessWidget {
  final ModCollection targetCollection;
  final List<ModCollection> conflictingCollections;
  final VoidCallback onConfirm;

  const ExclusiveConflictDialog({
    Key? key,
    required this.targetCollection,
    required this.conflictingCollections,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('互斥合集冲突'),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '"${targetCollection.name}" 是一个互斥合集。启用它将会自动禁用以下互斥合集：',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // 冲突合集列表
            for (final collection in conflictingCollections)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '将禁用 ${collection.modIds.length} 个模组',
                      style: const TextStyle(fontSize: 12, color: Colors.red),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // 警告信息
            const Text(
              '注意：此操作可能会导致游戏配置发生较大变化，请确保了解这些修改的影响。',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('确认启用'),
        ),
      ],
    );
  }
}

/// 显示互斥冲突确认对话框的便捷方法
Future<bool> showExclusiveConflictDialog(
  BuildContext context,
  ModCollection targetCollection,
  List<ModCollection> conflictingCollections,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => ExclusiveConflictDialog(
      targetCollection: targetCollection,
      conflictingCollections: conflictingCollections,
      onConfirm: () {
        Navigator.of(context).pop(true);
      },
    ),
  );
  
  return confirmed ?? false;
}
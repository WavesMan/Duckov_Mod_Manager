import 'package:flutter/material.dart';
import '../../services/theme_manager.dart';

class BatchControls extends StatelessWidget {
  final bool visible;
  final int selectedCount;
  final VoidCallback onEnableSelected;
  final VoidCallback onDisableSelected;

  const BatchControls({
    Key? key,
    required this.visible,
    required this.selectedCount,
    required this.onEnableSelected,
    required this.onDisableSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          Text(
            '已选择 $selectedCount 个创意工坊模组',
            style: TextStyle(
              color: ThemeManager.getThemeColor('text_primary'),
            ),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: onEnableSelected,
            icon: const Icon(Icons.check_circle),
            label: const Text('启用选中'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: onDisableSelected,
            icon: const Icon(Icons.cancel),
            label: const Text('禁用选中'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
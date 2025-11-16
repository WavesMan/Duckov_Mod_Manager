import 'package:flutter/material.dart';

class SyncStatusBanner extends StatelessWidget {
  final bool show;
  final String lastSyncResult;
  final VoidCallback onClose;

  const SyncStatusBanner({
    Key? key,
    required this.show,
    required this.lastSyncResult,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!show && lastSyncResult.isEmpty) return const SizedBox.shrink();
    final isSuccess = lastSyncResult.contains('完成');
    final bgColor = isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    final borderColor = isSuccess ? Colors.green : Colors.red;
    final textColor = isSuccess ? Colors.green[700] : Colors.red[700];
    final icon = isSuccess ? Icons.check_circle : Icons.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: borderColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              lastSyncResult,
              style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: Icon(Icons.close, size: 16, color: textColor),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }
}
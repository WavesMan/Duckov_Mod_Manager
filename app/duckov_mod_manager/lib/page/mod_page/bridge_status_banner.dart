import 'package:flutter/material.dart';

class BridgeStatusBanner extends StatelessWidget {
  final bool isConnected;
  final bool isChecking;
  final VoidCallback onRetry;

  const BridgeStatusBanner({
    Key? key,
    required this.isConnected,
    required this.isChecking,
    required this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isConnected || isChecking) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: isConnected ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(isConnected ? Icons.check_circle : Icons.warning, color: isConnected ? Colors.green : Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isConnected ? 'Bridge API 已连接 - 实时模组管理可用' : isChecking ? '正在检查Bridge API连接...' : 'Bridge API 未连接 - 使用文件系统模式',
                style: TextStyle(color: isConnected ? Colors.green : Colors.orange, fontSize: 12),
              ),
            ),
            if (!isConnected && !isChecking)
              TextButton(onPressed: onRetry, child: const Text('重试', style: TextStyle(fontSize: 12))),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
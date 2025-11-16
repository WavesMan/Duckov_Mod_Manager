import 'package:flutter/material.dart';

class BridgeStatusIndicator extends StatelessWidget {
  final bool isConnected;
  final bool isChecking;
  final VoidCallback onReconnect;

  const BridgeStatusIndicator({
    Key? key,
    required this.isConnected,
    required this.isChecking,
    required this.onReconnect,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isConnected ? Icons.link : Icons.link_off,
            color: isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            'Bridge',
            style: TextStyle(
              color: isConnected ? Colors.green : Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (!isConnected && !isChecking) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onReconnect,
              icon: const Icon(Icons.refresh, size: 30, color: Colors.orange),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              tooltip: '重连Bridge API',
            ),
          ],
        ],
      ),
    );
  }
}
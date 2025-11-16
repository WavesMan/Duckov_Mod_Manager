import 'package:flutter/material.dart';

class SyncProgressBar extends StatelessWidget {
  final bool isSyncInProgress;
  final double progress;
  final String progressText;

  const SyncProgressBar({
    Key? key,
    required this.isSyncInProgress,
    required this.progress,
    required this.progressText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isSyncInProgress) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: const Border(bottom: BorderSide(color: Colors.blue, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sync, color: Colors.blue, size: 16),
              const SizedBox(width: 8),
              const Text('Bridge 同步进行中', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
              const Spacer(),
              if (progress > 0 && progress < 1.0)
                Text('${(progress * 100).toInt()}%', style: const TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
          if (progressText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(progressText, style: TextStyle(color: Colors.blue[700], fontSize: 11)),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress, backgroundColor: Colors.blue.withOpacity(0.3), valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue)),
        ],
      ),
    );
  }
}
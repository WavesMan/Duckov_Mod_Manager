import 'package:flutter/material.dart';
import '../../services/theme_manager.dart';

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: onPrev,
          ),
          Text(
            '第 $currentPage 页 / 共 $totalPages 页',
            style: TextStyle(
              color: ThemeManager.getThemeColor('text_secondary'),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
// test_animation.dart
/// 测试页面切换动画效果的临时文件

import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  final String title;
  final Color color;
  final int pageIndex;

  const TestPage({
    Key? key,
    required this.title,
    required this.color,
    required this.pageIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey(pageIndex),
      child: Column(
        children: [
          // 页面标题
          Text(
            title,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 20),
          // 测试内容
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color, width: 2),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.animation,
                    size: 64,
                    color: color,
                  ),
                  SizedBox(height: 16),
                  Text(
                    '页面切换动画测试',
                    style: TextStyle(
                      fontSize: 18,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '当前页面: $title',
                    style: TextStyle(
                      fontSize: 14,
                      color: color.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
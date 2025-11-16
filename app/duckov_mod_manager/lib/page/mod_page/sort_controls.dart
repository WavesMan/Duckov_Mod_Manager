import 'package:flutter/material.dart';
import '../../services/theme_manager.dart';

class SortControls extends StatelessWidget {
  final String sortBy;
  final ValueChanged<String> onChangeSortBy;
  final bool sortReverse;
  final VoidCallback onToggleReverse;

  const SortControls({
    Key? key,
    required this.sortBy,
    required this.onChangeSortBy,
    required this.sortReverse,
    required this.onToggleReverse,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 确保当前选中的值在选项列表中存在
    String currentSortBy = sortBy;
    final List<String> validSortOptions = ['name', 'enabled', 'size', 'id'];
    if (!validSortOptions.contains(currentSortBy)) {
      currentSortBy = 'name'; // 默认使用 name 作为排序方式
    }

    return Row(
      children: [
        Text('排序:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: ThemeManager.getThemeColor('text_secondary'),
            )
        ),
        const SizedBox(width: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: currentSortBy,
            dropdownColor: ThemeManager.getThemeColor('background'),
            onChanged: (value) {
              if (value != null) onChangeSortBy(value);
            },
            // 将 const 改为非 const，因为需要调用方法获取颜色
            items: [
              DropdownMenuItem(
                  value: 'name',
                  child: Text(
                      '名称',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeManager.getThemeColor('text_secondary'),
                      )
                  )
              ),
              DropdownMenuItem(
                  value: 'enabled',
                  child: Text(
                      '启用状态',
                      style: TextStyle(
                          fontSize: 12,
                          color: ThemeManager.getThemeColor('text_secondary'),
                      )
                  )
              ),
              DropdownMenuItem(
                  value: 'size',
                  child: Text(
                      '大小',
                      style: TextStyle(
                          fontSize: 12,
                          color: ThemeManager.getThemeColor('text_secondary'),
                      )
                  )
              ),
              DropdownMenuItem(
                  value: 'id',
                  child: Text(
                      'ID',
                      style: TextStyle(
                          fontSize: 12,
                          color: ThemeManager.getThemeColor('text_secondary'),
                      )
                  )
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(
              sortReverse ? Icons.arrow_upward : Icons.arrow_downward,
              color: ThemeManager.getThemeColor('text_secondary'),
              size: 18
          ),
          onPressed: onToggleReverse,
          tooltip: sortReverse ? '升序' : '降序',
        ),
      ],
    );
  }
}
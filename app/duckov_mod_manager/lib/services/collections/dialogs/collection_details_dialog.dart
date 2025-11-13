// collection_details_dialog.dart
/// 合集详情展示对话框

import 'package:flutter/material.dart';
import 'package:duckov_mod_manager/services/collections/mod_collection.dart' as model;
import 'package:duckov_mod_manager/services/mod_manager.dart';
import '../../theme_manager.dart';

/// 显示合集详情对话框
Future<void> showCollectionDetailsDialog(
  BuildContext context, 
  model.ModCollection collection,
  List<ModInfo> allMods,
) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return CollectionDetailsDialog(
        collection: collection,
        allMods: allMods,
      );
    },
  );
}

class CollectionDetailsDialog extends StatefulWidget {
  final model.ModCollection collection;
  final List<ModInfo> allMods;

  const CollectionDetailsDialog({
    Key? key,
    required this.collection,
    required this.allMods,
  }) : super(key: key);

  @override
  CollectionDetailsDialogState createState() => CollectionDetailsDialogState();
}

class CollectionDetailsDialogState extends State<CollectionDetailsDialog> {
  String _searchQuery = '';
  List<ModInfo> _filteredMods = [];

  @override
  void initState() {
    super.initState();
    _filterMods();
  }

  void _filterMods() {
    final collectionMods = widget.collection.modIds
        .map((modId) => widget.allMods
            .where((mod) => mod.id == modId || mod.name == modId)
            .firstOrNull)
        .where((mod) => mod != null)
        .cast<ModInfo>()
        .toList();

    if (_searchQuery.isEmpty) {
      _filteredMods = collectionMods;
    } else {
      _filteredMods = collectionMods.where((mod) {
        return mod.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               mod.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               mod.description.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题区域
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.collection.name,
                        style: ThemeManager.headingTextStyle(level: 2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.collection.description,
                        style: ThemeManager.bodyTextStyle(size: 14, color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (widget.collection.exclusive)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block, size: 16, color: Colors.red),
                        SizedBox(width: 4),
                        Text(
                          '互斥模式',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            SizedBox(height: 20),

            // 统计信息
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      '模组数量',
                      '${widget.collection.modIds.length}',
                      Icons.extension,
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '创建时间',
                      _formatDate(widget.collection.createdAt),
                      Icons.calendar_today,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      '更新时间',
                      _formatDate(widget.collection.updatedAt),
                      Icons.update,
                      Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // 搜索栏
            TextField(
              decoration: InputDecoration(
                hintText: '搜索模组...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _filterMods();
              },
            ),
            SizedBox(height: 16),

            // 模组列表标题
            Row(
              children: [
                Icon(Icons.list_alt, size: 20, color: Colors.grey[600]),
                SizedBox(width: 8),
                Text(
                  '包含的模组 (${_filteredMods.length})',
                  style: ThemeManager.bodyTextStyle(
                    size: 16,
                    color: Colors.grey[800],
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            SizedBox(height: 12),

            // 模组列表 - 两列瀑布布局
            Expanded(
              child: _filteredMods.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? '暂无模组数据' : '未找到匹配的模组',
                            style: ThemeManager.bodyTextStyle(
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            childAspectRatio: crossAxisCount == 2 ? 3.5 : 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _filteredMods.length,
                          itemBuilder: (context, index) {
                            final mod = _filteredMods[index];
                            return _buildModCard(mod);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildModCard(ModInfo mod) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 模组标题和版本
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mod.displayName.isNotEmpty ? mod.displayName : mod.name,
                        style: ThemeManager.bodyTextStyle(
                          size: 14,
                        ).copyWith(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ID: ${mod.id}',
                        style: ThemeManager.bodyTextStyle(
                          size: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (mod.author != null && mod.author!.isNotEmpty) ...[
                        SizedBox(height: 2),
                        Text(
                          '作者: ${mod.author}',
                          style: ThemeManager.bodyTextStyle(
                            size: 11,
                            color: Colors.green[700],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    mod.version,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.blue,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),

            // 模组描述（滚动显示）
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: Scrollbar(
                      child: Text(
                        mod.description.isNotEmpty 
                            ? mod.description 
                            : '暂无描述',
                        style: ThemeManager.bodyTextStyle(size: 12).copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 8),

            // 底部信息
            Row(
              children: [
                Icon(
                  Icons.folder,
                  size: 12,
                  color: Colors.grey[500],
                ),
                SizedBox(width: 4),
                Expanded(
                  child: Text(
                    mod.size,
                    style: ThemeManager.bodyTextStyle(
                      size: 10,
                      color: Colors.grey[500],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 扩展方法：获取列表中的第一个非空元素
extension FirstOrNullExtension<T> on Iterable<T> {
  T? get firstOrNull {
    try {
      return first;
    } catch (e) {
      return null;
    }
  }
}
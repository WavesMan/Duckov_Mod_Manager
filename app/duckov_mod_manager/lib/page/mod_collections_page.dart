// mod_collections_page.dart
/// Mod合集页面

import 'package:flutter/material.dart';
import 'package:duckov_mod_manager/services/collections/mod_collection.dart' as model;
import 'package:duckov_mod_manager/services/collections/collection_service.dart';
import 'package:duckov_mod_manager/services/collections/dialogs/collection_edit_dialog.dart';
import 'package:duckov_mod_manager/services/collections/dialogs/exclusive_conflict_dialog.dart';
import 'package:duckov_mod_manager/services/collections/dialogs/collection_details_dialog.dart';
import '../services/mod_manager.dart';
import '../services/theme_manager.dart';

class ModCollectionsPage extends StatefulWidget {
  const ModCollectionsPage({Key? key}) : super(key: key);

  @override
  ModCollectionsPageState createState() => ModCollectionsPageState();
}

class ModCollectionsPageState extends State<ModCollectionsPage> {
  String _searchQuery = '';
  String? _searchError;

  @override
  Widget build(BuildContext context) {
    return Container(
      // 跟随主题的 surface 颜色（亮主题是白色，暗主题是深灰）
        color: ThemeManager.getThemeColor('surface'),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headingText('Mod合集 BETA', level: 1),
              SizedBox(height: 20),
              bodyText('创建和管理您自己的模组合集，快速启用或禁用相关模组。'),
              SizedBox(height: 30),
          
            // 操作栏
            _buildActionBar(),
            SizedBox(height: 16),

            // 搜索栏
            _buildSearchBar(),
            SizedBox(height: 20),

            // 合集列表
            StreamBuilder<List<model.ModCollection>>(
              stream: collectionService.collections$,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        '加载合集失败: ${snapshot.error}',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }

                final collections = snapshot.data ?? [];
                final filteredCollections = collections.where((c) {
                  return c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         c.description.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();

                if (filteredCollections.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.collections_outlined, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty ? '还没有创建任何合集' : '没有找到匹配的合集',
                            style: ThemeManager.bodyTextStyle(size: 16),
                            textAlign: TextAlign.center,
                          ),
                          if (_searchQuery.isEmpty)
                            SizedBox(height: 16),
                          if (_searchQuery.isEmpty)
                            ElevatedButton(
                              onPressed: _createNewCollection,
                              child: Text('创建第一个合集'),
                            ),
                        ],
                      ),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    final crossAxisCount = screenWidth > 800 ? 2 : 1;
                    final childAspectRatio = crossAxisCount == 2 ? 1.6 : 1.5;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: childAspectRatio,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: filteredCollections.length,
                      itemBuilder: (context, index) {
                        return _buildCollectionCard(filteredCollections[index]);
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: 150,
        child: ElevatedButton.icon(
          onPressed: _createNewCollection,
          icon: Icon(Icons.add),
          label: Text(
              '创建新合集',
              style: TextStyle(
                color: Colors.white,
              )
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 12),
            backgroundColor: Colors.blue,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索合集...',
          // 添加文本颜色
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  Widget _buildCollectionCard(model.ModCollection collection) {
    return Card(
      elevation: 3,
      // 卡片跟随滚动
      color: ThemeManager.getThemeColor('background'),
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 合集标题和主要标签
            Row(
              children: [
                Expanded(
                  child: Text(
                    collection.name,
                    style: ThemeManager.headingTextStyle(level: 4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: collection.exclusive 
                        ? Colors.red.withOpacity(0.1) 
                        : Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    collection.exclusive ? '互斥' : '常规',
                    style: TextStyle(
                      color: collection.exclusive ? Colors.red : Colors.green,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 6),
            
            // 模组数量标签
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.extension, size: 10, color: Colors.blue),
                  SizedBox(width: 3),
                  Text(
                    '${collection.modIds.length}',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 8),
            
            // 描述文本
            Container(
              height: 45,
              child: Text(
                collection.description,
                style: ThemeManager.bodyTextStyle(size: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            
            SizedBox(height: 8),
            
            // 时间信息
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.05),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 8, color: Colors.grey),
                      SizedBox(width: 3),
                      Text(
                        '创建: ${_formatDate(collection.createdAt)}',
                        style: ThemeManager.bodyTextStyle(
                          size: 11,
                          color: Colors.grey[600]
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(Icons.update, size: 8, color: Colors.grey),
                      SizedBox(width: 3),
                      Text(
                        '更新: ${_formatDate(collection.updatedAt)}',
                        style: ThemeManager.bodyTextStyle(
                          size: 11,
                          color: Colors.grey[600]
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 10),
            
            // 主要操作按钮组
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _viewCollectionDetails(collection),
                    icon: Icon(
                        Icons.info_outline,
                        size: 12,
                        color: ThemeManager.getThemeColor('text_secondary')
                    ),
                    label: Text(
                        '详情',
                        style: TextStyle(
                            fontSize: 15,
                            color: ThemeManager.getThemeColor('text_secondary')
                        )
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      backgroundColor: ThemeManager.getThemeColor('surface'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async => await _enableCollection(collection),
                    icon: Icon(Icons.play_arrow, size: 13, color: Colors.white),
                    label: Text('启用',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white
                        )
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 4),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async => await _disableCollection(collection),
                    icon: Icon(Icons.stop, size: 13),
                    label: Text('禁用', style: TextStyle(fontSize: 15)),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      foregroundColor: Colors.orange,
                      side: BorderSide(color: Colors.orange),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 4),
            
            // 次要操作按钮组
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async => await _editCollection(collection),
                    icon: Icon(Icons.edit, size: 13, color: Colors.white,),
                    label: Text(
                        '编辑',
                        style: TextStyle(
                            fontSize: 15,
                            color: Colors.white
                        )
                    ),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      backgroundColor: ThemeManager.getThemeColor('edit_color'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async => await _deleteCollection(collection),
                    icon: Icon(Icons.delete_outline, size: 13, color: Colors.red),
                    label: Text('删除', style: TextStyle(fontSize: 15, color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
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

  Future<void> _createNewCollection() async {
    try {
      final mods = await modManager.getDownloadedMods();
      
      if (mods.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('没有已下载的模组，请先下载模组')),
          );
        }
        return;
      }
      
      final newCollection = await showCollectionEditDialog(context, mods);
      if (newCollection != null) {
        await collectionService.add(newCollection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('合集创建成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建合集失败: $e')),
        );
      }
    }
  }

  Future<void> _editCollection(model.ModCollection collection) async {
    try {
      final mods = await modManager.getDownloadedMods();
      
      final updatedCollection = await showCollectionEditDialog(context, mods, collection: collection);
      if (updatedCollection != null) {
        await collectionService.update(updatedCollection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('合集更新成功')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('更新合集失败: $e')),
        );
      }
    }
  }

  Future<void> _viewCollectionDetails(model.ModCollection collection) async {
    try {
      // 获取所有模组信息
      final allMods = await modManager.getDownloadedMods();
      
      // 显示新的详情对话框
      await showCollectionDetailsDialog(context, collection, allMods);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载模组详情失败: $e')),
        );
      }
    }
  }

  Future<void> _enableCollection(model.ModCollection collection) async {
    if (collection.exclusive) {
      // 检测互斥冲突
      final conflictingCollections = collectionService.getConflictingCollections(collection);
      
      if (conflictingCollections.isNotEmpty) {
        // 显示冲突确认对话框
        final confirmed = await showExclusiveConflictDialog(
          context,
          collection,
          conflictingCollections,
        );
        
        if (confirmed) {
          try {
            await collectionService.enableCollection(collection);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('合集启用成功')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('启用合集失败: $e')),
              );
            }
          }
        }
        return;
      }
    }
    
    // 非互斥合集或无冲突，使用原来的确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('启用合集'),
          content: Text('确定要启用"${collection.name}"合集吗？这将启用${collection.modIds.length}个模组。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('确定'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        await collectionService.enableCollection(collection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('合集启用成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('启用合集失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _disableCollection(model.ModCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('禁用合集'),
          content: Text('确定要禁用"${collection.name}"合集吗？这将禁用${collection.modIds.length}个模组。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('确定'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        await collectionService.disableCollection(collection);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('合集禁用成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('禁用合集失败: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteCollection(model.ModCollection collection) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('删除合集'),
          content: Text('确定要删除"${collection.name}"合集吗？此操作不可撤销。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: Text('删除'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        await collectionService.remove(collection.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('合集删除成功')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('删除合集失败: $e')),
          );
        }
      }
    }
  }
}

/// 便捷函数 - 创建Mod合集页面视图
Widget modCollectionsPageView() {
  return ModCollectionsPage();
}
// mod_collections_page.dart
/// Mod合集页面

import 'package:flutter/material.dart';
import 'package:duckov_mod_manager/services/collections/mod_collection.dart' as model;
import 'package:duckov_mod_manager/services/collections/collection_service.dart';
import 'package:duckov_mod_manager/services/collections/dialogs/collection_edit_dialog.dart';
import 'package:duckov_mod_manager/services/collections/dialogs/exclusive_conflict_dialog.dart';
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headingText('Mod合集', level: 1),
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
              
              return ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: filteredCollections.length,
                itemBuilder: (context, index) {
                  return _buildCollectionCard(filteredCollections[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _createNewCollection,
        icon: Icon(Icons.add),
        label: Text('创建新合集'),
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
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
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    collection.name,
                    style: ThemeManager.headingTextStyle(level: 3),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    if (collection.exclusive)
                      Chip(
                        label: Text('互斥'),
                        backgroundColor: Colors.red.withOpacity(0.1),
                        labelStyle: TextStyle(color: Colors.red),
                        visualDensity: VisualDensity.compact,
                      ),
                    SizedBox(width: 8),
                    Chip(
                      label: Text('${collection.modIds.length}个模组'),
                      backgroundColor: Colors.blue.withOpacity(0.1),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              collection.description,
              style: ThemeManager.bodyTextStyle(size: 14),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Text(
                  '创建于: ${_formatDate(collection.createdAt)}',
                  style: ThemeManager.bodyTextStyle(size: 12, color: Colors.grey),
                ),
                Spacer(),
                Text(
                  '更新于: ${_formatDate(collection.updatedAt)}',
                  style: ThemeManager.bodyTextStyle(size: 12, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _viewCollectionDetails(collection),
                    child: Text('详情'),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async => await _enableCollection(collection),
                  child: Text('启用'),
                ),
                SizedBox(width: 8),
                PopupMenuButton<dynamic>(
                  icon: Icon(Icons.more_vert),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text('编辑合集'),
                      onTap: () async => await _editCollection(collection),
                    ),
                    PopupMenuItem(
                      child: Text('禁用合集'),
                      onTap: () async => await _disableCollection(collection),
                    ),
                    PopupMenuDivider(),
                    PopupMenuItem(
                      child: Text('删除合集', style: TextStyle(color: Colors.red)),
                      onTap: () async => await _deleteCollection(collection),
                    ),
                  ],
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

  void _viewCollectionDetails(model.ModCollection collection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(collection.name),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('描述: ${collection.description}'),
                SizedBox(height: 8),
                Text('模组数量: ${collection.modIds.length}'),
                SizedBox(height: 8),
                Text('互斥模式: ${collection.exclusive ? '是' : '否'}'),
                SizedBox(height: 8),
                Text('创建时间: ${collection.createdAt.toString()}'),
                SizedBox(height: 8),
                Text('更新时间: ${collection.updatedAt.toString()}'),
                SizedBox(height: 16),
                Text('包含的模组ID列表:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(collection.modIds.join('\n')),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('关闭'),
            ),
          ],
        );
      },
    );
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
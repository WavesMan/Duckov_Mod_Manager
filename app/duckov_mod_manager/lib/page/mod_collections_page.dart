// mod_collections_page.dart
/// Mod合集页面

import 'package:flutter/material.dart';
import '../services/theme_manager.dart';

class ModCollectionsPage extends StatefulWidget {
  const ModCollectionsPage({Key? key}) : super(key: key);

  @override
  ModCollectionsPageState createState() => ModCollectionsPageState();
}

class ModCollectionsPageState extends State<ModCollectionsPage> {
  final List<ModCollection> _collections = [
    ModCollection(
      name: '生存模式增强',
      description: '包含各种生存相关的模组，提升游戏生存体验',
      modCount: 12,
      author: '社区玩家',
      rating: 4.8,
      downloads: 1500,
    ),
    ModCollection(
      name: '建筑与装饰',
      description: '丰富的建筑材料和装饰物品模组',
      modCount: 8,
      author: '建筑大师',
      rating: 4.5,
      downloads: 2300,
    ),
    ModCollection(
      name: '武器与装备',
      description: '新增各种武器、装备和战斗系统',
      modCount: 15,
      author: '战斗专家',
      rating: 4.7,
      downloads: 1800,
    ),
    ModCollection(
      name: '魔法与奇幻',
      description: '魔法系统、奇幻生物和神秘力量',
      modCount: 10,
      author: '魔法师',
      rating: 4.9,
      downloads: 1200,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          headingText('Mod合集', level: 1),
          SizedBox(height: 20),
          bodyText('浏览和管理预设的模组合集，快速安装相关模组。'),
          SizedBox(height: 30),
          
          // 搜索栏
          _buildSearchBar(),
          SizedBox(height: 20),
          
          // 合集列表
          _buildCollectionsList(),
        ],
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
          // 搜索逻辑
        },
      ),
    );
  }

  Widget _buildCollectionsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: _collections.length,
      itemBuilder: (context, index) {
        return _buildCollectionCard(_collections[index]);
      },
    );
  }

  Widget _buildCollectionCard(ModCollection collection) {
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
                Chip(
                  label: Text('${collection.modCount}个模组'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              collection.description,
              style: ThemeManager.bodyTextStyle(size: 14),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  collection.author,
                  style: ThemeManager.bodyTextStyle(size: 12, color: Colors.grey),
                ),
                Spacer(),
                Icon(Icons.star, size: 16, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  collection.rating.toString(),
                  style: ThemeManager.bodyTextStyle(size: 12),
                ),
                SizedBox(width: 16),
                Icon(Icons.download, size: 16, color: Colors.green),
                SizedBox(width: 4),
                Text(
                  '${collection.downloads}',
                  style: ThemeManager.bodyTextStyle(size: 12),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _viewCollectionDetails(collection);
                    },
                    child: Text('查看详情'),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _installCollection(collection);
                    },
                    child: Text('安装合集'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewCollectionDetails(ModCollection collection) {
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
                Text('作者: ${collection.author}'),
                SizedBox(height: 8),
                Text('模组数量: ${collection.modCount}'),
                SizedBox(height: 8),
                Text('评分: ${collection.rating}'),
                SizedBox(height: 8),
                Text('下载量: ${collection.downloads}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('关闭'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _installCollection(collection);
              },
              child: Text('安装合集'),
            ),
          ],
        );
      },
    );
  }

  void _installCollection(ModCollection collection) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('安装合集'),
          content: Text('确定要安装"${collection.name}"合集吗？这将安装${collection.modCount}个模组。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('取消'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('开始安装"${collection.name}"合集...')),
                );
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }
}

class ModCollection {
  final String name;
  final String description;
  final int modCount;
  final String author;
  final double rating;
  final int downloads;

  ModCollection({
    required this.name,
    required this.description,
    required this.modCount,
    required this.author,
    required this.rating,
    required this.downloads,
  });
}

/// 便捷函数 - 创建Mod合集页面视图
Widget modCollectionsPageView() {
  return ModCollectionsPage();
}
// mod_page.dart
/// 模组管理页面 - 基于Flet的mods_page.py重构

import 'dart:io';
import 'package:flutter/material.dart';
import '../services/mod_manager.dart';
import '../services/theme_manager.dart';

class ModPage extends StatefulWidget {
  const ModPage({Key? key}) : super(key: key);

  @override
  State<ModPage> createState() => _ModPageState();
}

class _ModPageState extends State<ModPage> with SingleTickerProviderStateMixin {
  final ModManager _modManager = modManager;
  List<ModInfo> _mods = [];
  List<ModInfo> _filteredMods = [];
  List<ModInfo> _localMods = [];
  List<String> _selectedModIds = [];
  bool _isLoading = true;
  bool _isLoadingLocal = false;
  bool _selectAll = false;
  String _searchQuery = '';
  String _sortBy = 'name';
  bool _sortReverse = false;
  int _currentPage = 1;
  int _totalPages = 1;
  final int _pageSize = 16;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadMods();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _modManager.getDownloadedModsPaginated(
        page: _currentPage,
        pageSize: _pageSize,
      );

      setState(() {
        _mods = result.mods;
        _totalPages = result.totalPages;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      print('[ModPage] 加载模组时出错: $e');
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('加载模组失败: $e');
    }
  }

  Future<void> _loadLocalMods() async {
    setState(() {
      _isLoadingLocal = true;
    });

    try {
      final localMods = await _modManager.getLocalMods();
      setState(() {
        _localMods = localMods;
        if (_tabController.index == 1) {
          _applyFilters();
        }
        _isLoadingLocal = false;
      });
    } catch (e) {
      print('[ModPage] 加载本地模组时出错: $e');
      setState(() {
        _isLoadingLocal = false;
      });
      _showErrorDialog('加载本地模组失败: $e');
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedModIds.clear();
      _selectAll = false;
      _searchQuery = '';
    });
    
    // 根据切换的标签页加载相应的模组
    if (index == 0 && _mods.isEmpty) {
      _loadMods();
    } else if (index == 1 && _localMods.isEmpty) {
      _loadLocalMods();
    } else {
      _applyFilters();
    }
  }

  void _applyFilters() {
    List<ModInfo> filtered;
    
    // 根据当前标签页选择要过滤的模组列表
    if (_tabController.index == 0) {
      filtered = List.from(_mods);
    } else {
      filtered = List.from(_localMods);
    }

    // 应用搜索过滤
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((mod) =>
          mod.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mod.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // 应用排序
    filtered = _modManager.sortMods(filtered, _sortBy, reverse: _sortReverse);

    setState(() {
      _filteredMods = filtered;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('错误'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('成功'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadMods(); // 重新加载模组列表
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedModIds = _filteredMods.map((mod) => mod.id).toList();
      } else {
        _selectedModIds.clear();
      }
    });
  }

  void _toggleModSelection(String modId, bool selected) {
    setState(() {
      if (selected) {
        _selectedModIds.add(modId);
      } else {
        _selectedModIds.remove(modId);
      }
      _selectAll = _selectedModIds.length == _filteredMods.length;
    });
  }

  Future<void> _enableSelectedMods() async {
    if (_selectedModIds.isEmpty) return;

    final results = await _modManager.batchEnableMods(_selectedModIds);
    final successCount = results.values.where((result) => result).length;
    
    _showSuccessDialog('成功启用 $successCount/${_selectedModIds.length} 个模组');
    setState(() {
      _selectedModIds.clear();
      _selectAll = false;
    });
  }

  Future<void> _disableSelectedMods() async {
    if (_selectedModIds.isEmpty) return;

    final results = await _modManager.batchDisableMods(_selectedModIds);
    final successCount = results.values.where((result) => result).length;
    
    _showSuccessDialog('成功禁用 $successCount/${_selectedModIds.length} 个模组');
    setState(() {
      _selectedModIds.clear();
      _selectAll = false;
    });
  }

  Future<void> _toggleModStatus(String modId) async {
    try {
      final isEnabled = await _modManager.isModEnabled(modId);
      final success = isEnabled 
          ? await _modManager.disableMod(modId)
          : await _modManager.enableMod(modId);

      if (success) {
        _showSuccessDialog(isEnabled ? '模组已禁用' : '模组已启用');
      } else {
        _showErrorDialog('操作失败');
      }
    } catch (e) {
      _showErrorDialog('操作失败: $e');
    }
  }

  void _showModDetails(ModInfo mod) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(mod.displayName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${mod.id}'),
              const SizedBox(height: 8),
              Text('名称: ${mod.name}'),
              const SizedBox(height: 8),
              Text('版本: ${mod.version}'),
              const SizedBox(height: 8),
              Text('大小: ${mod.size}'),
              const SizedBox(height: 8),
              Text('描述: ${mod.description}'),
              const SizedBox(height: 8),
              Text('路径: ${mod.path}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SizedBox(
      height: 36,
      child: TextField(
        decoration: InputDecoration(
          hintText: '搜索模组...',
          prefixIcon: const Icon(Icons.search, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                )
              : null,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
      ),
    );
  }

  Widget _buildSortControls() {
    return Row(
      children: [
        const Text('排序:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 4),
        DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _sortBy,
            onChanged: (value) {
              setState(() {
                _sortBy = value!;
                _applyFilters();
              });
            },
            items: const [
              DropdownMenuItem(value: 'name', child: Text('名称', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'status', child: Text('状态', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'size', child: Text('大小', style: TextStyle(fontSize: 12))),
              DropdownMenuItem(value: 'id', child: Text('ID', style: TextStyle(fontSize: 12))),
            ],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: Icon(_sortReverse ? Icons.arrow_upward : Icons.arrow_downward, size: 18),
          onPressed: () {
            setState(() {
              _sortReverse = !_sortReverse;
              _applyFilters();
            });
          },
          tooltip: _sortReverse ? '升序' : '降序',
        ),
      ],
    );
  }

  Widget _buildBatchControls() {
    // 只对创意工坊模组显示批量操作
    if (_tabController.index != 0 || _selectedModIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        children: [
          Text('已选择 ${_selectedModIds.length} 个创意工坊模组'),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _enableSelectedMods,
            icon: const Icon(Icons.check_circle),
            label: const Text('启用选中'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _disableSelectedMods,
            icon: const Icon(Icons.cancel),
            label: const Text('禁用选中'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModPreview(ModInfo mod) {
    if (mod.previewImagePath != null) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(mod.previewImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultPreview();
            },
          ),
        ),
      );
    } else {
      return _buildDefaultPreview();
    }
  }

  Widget _buildDefaultPreview() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 32,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            '无预览图',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildModDescription(String description) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Scrollbar(
            child: Text(
              description.isEmpty ? '暂无描述' : description,
              style: ThemeManager.bodyTextStyle().copyWith(
                fontSize: 11,
                color: Colors.grey[700],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModStats(ModInfo mod, bool isEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled ? Colors.green : Colors.grey,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isEnabled ? '已启用' : '已禁用',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Text(
          'v${mod.version}',
          style: ThemeManager.bodyTextStyle().copyWith(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        Text(
          mod.size,
          style: ThemeManager.bodyTextStyle().copyWith(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ModInfo mod, bool isEnabled) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _toggleModStatus(mod.id),
            icon: Icon(isEnabled ? Icons.toggle_on : Icons.toggle_off),
            label: Text(isEnabled ? '禁用' : '启用'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isEnabled ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showModDetails(mod),
            icon: const Icon(Icons.info, size: 16),
            label: const Text('详情'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              textStyle: const TextStyle(fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModCard(ModInfo mod) {
    final isSelected = _selectedModIds.contains(mod.id);

    return FutureBuilder<bool>(
      future: _modManager.isModEnabled(mod.id),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        
        return Card(
          elevation: 3,
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => _toggleModSelection(mod.id, !isSelected),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 左侧：1:1图片
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _buildModPreview(mod),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // 中间：名称和描述
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 选择框和标题
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) => _toggleModSelection(mod.id, value ?? false),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            Expanded(
                              child: Text(
                                mod.displayName,
                                style: ThemeManager.headingTextStyle(level: 5),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // 统计信息
                        _buildModStats(mod, isEnabled),
                        
                        const SizedBox(height: 6),
                        
                        // 描述文本（滚动）
                        Expanded(
                          child: SizedBox(
                            height: 80, // 设置固定高度
                            child: _buildModDescription(mod.description),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // 右侧：按钮列
                  Container(
                    width: 80,
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 启用/禁用按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _toggleModStatus(mod.id),
                            icon: Icon(isEnabled ? Icons.toggle_on : Icons.toggle_off, size: 16),
                            label: Text(isEnabled ? '禁用' : '启用', style: const TextStyle(fontSize: 15)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEnabled ? Colors.red : Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // 详情按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _showModDetails(mod),
                            icon: const Icon(Icons.info, size: 14),
                            label: const Text('详情', style: TextStyle(fontSize: 15)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: const BorderSide(color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPaginationControls() {
    if (_totalPages <= 1) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1 ? () {
              setState(() {
                _currentPage--;
                _loadMods();
              });
            } : null,
          ),
          Text('第 $_currentPage 页 / 共 $_totalPages 页'),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < _totalPages ? () {
              setState(() {
                _currentPage++;
                _loadMods();
              });
            } : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('模组管理'),
        backgroundColor: Colors.blue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(15), // 四个角都有圆角
          ),
        ),
        actions: [
          if (_selectedModIds.isNotEmpty && _tabController.index == 0) ...[
            IconButton(
              onPressed: _enableSelectedMods,
              icon: const Icon(Icons.check_circle),
              tooltip: '启用所选模组',
            ),
            IconButton(
              onPressed: _disableSelectedMods,
              icon: const Icon(Icons.cancel),
              tooltip: '禁用所选模组',
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          splashBorderRadius: BorderRadius.circular(15),
          onTap: _onTabChanged,
          tabs: [
            Tab(text: '创意工坊模组 (${_mods.length})'),
            Tab(text: '本地模组 (${_localMods.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 创意工坊模组页面
          _buildWorkshopModsPage(),
          // 本地模组页面
          _buildLocalModsPage(),
        ],
      ),
    );
  }

  Widget _buildWorkshopModsPage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 控制栏 - 紧凑布局
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // 全选控制
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                ),
                const Text('全选', style: TextStyle(fontSize: 12)),
                const Spacer(),
                // 搜索栏
                Expanded(flex: 3, child: _buildSearchBar()),
                const SizedBox(width: 8),
                // 排序控制
                _buildSortControls(),
              ],
            ),
          ),
          
          // 批量操作控制
          _buildBatchControls(),
          const SizedBox(height: 4),
          
          // 模组列表
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredMods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? '暂无创意工坊模组' : '未找到匹配的创意工坊模组',
                              style: ThemeManager.headingTextStyle(level: 4),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 6),
                              const Text('请确保已订阅并下载了创意工坊模组', style: TextStyle(fontSize: 11)),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3,
                        ),
                        itemCount: _filteredMods.length,
                        itemBuilder: (context, index) {
                          // 添加边界检查以防止数组越界错误
                          if (index >= _filteredMods.length || _filteredMods.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final mod = _filteredMods[index];
                          return _buildModCard(mod);
                        },
                      ),
          ),
          // 分页控制
          _buildPaginationControls(),
          ],
      ),
    );
  }

  Widget _buildLocalModsPage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 控制栏 - 紧凑布局
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // 本地模组信息
                const Icon(Icons.folder, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text(
                  '本地模组 (${_filteredMods.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // 搜索栏
                Expanded(flex: 3, child: _buildSearchBar()),
                const SizedBox(width: 8),
                // 排序控制
                _buildSortControls(),
              ],
            ),
          ),
          
          // 路径信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '路径: ${_localMods.isNotEmpty ? _localMods.first.path : '未找到路径'}',
              style: ThemeManager.bodyTextStyle().copyWith(
                fontSize: 9,
                color: Colors.grey[600],
              ),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // 模组列表
          Expanded(
            child: _isLoadingLocal
                ? const Center(child: CircularProgressIndicator())
                : _filteredMods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isEmpty ? '暂无本地模组' : '未找到匹配的本地模组',
                              style: ThemeManager.headingTextStyle(level: 4),
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 6),
                              const Text('请确保游戏模组目录存在且包含本地模组', style: TextStyle(fontSize: 11)),
                            ],
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 3,
                        ),
                        itemCount: _filteredMods.length,
                        itemBuilder: (context, index) {
                          // 添加边界检查以防止数组越界错误
                          if (index >= _filteredMods.length || _filteredMods.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final mod = _filteredMods[index];
                          return _buildModCard(mod);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

/// 便捷函数 - 创建模组页面视图
Widget modsPageView() {
  return const ModPage();
}
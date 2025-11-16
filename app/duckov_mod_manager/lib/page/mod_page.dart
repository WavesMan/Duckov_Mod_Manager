// mod_page.dart
/// 模组管理页面 - 基于Flet的mods_page.py重构
// library mod_page; // 暂不使用 library/part 机制

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/mod_manager.dart';
import '../services/theme_manager.dart';
import '../services/config_manager.dart';
import 'mod_page/mod_card.dart';
import 'mod_page/batch_controls.dart';
import 'mod_page/pagination_controls.dart';
import 'mod_page/search_bar.dart';
import 'mod_page/sort_controls.dart';
import 'mod_page/views/workshop_mods_view.dart';
import 'mod_page/views/local_mods_view.dart';
import 'mod_page/dialogs/mod_details_dialog.dart';
import 'mod_page/dialogs/alerts.dart';



class ModPage extends StatefulWidget {
  const ModPage({Key? key}) : super(key: key);

  @override
  State<ModPage> createState() => _ModPageState();
}

class _ModPageState extends State<ModPage>
    with SingleTickerProviderStateMixin {
  final ModManager _modManager = modManager;
  List<LocalModInfo> _mods = [];
  List<LocalModInfo> _filteredMods = [];
  List<LocalModInfo> _localMods = [];
  Set<String> _selectedModIds = <String>{};
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
  late ScrollController _scrollController;
  bool _showScrollTopButton = false;
  void _onThemeChanged() {
    if (!mounted) return;
    setState(() {});
  }
  
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _onTabChanged(_tabController.index);
      }
    });
    _loadMods();
    
    
    
    // 添加滚动监听器
    _scrollController = ScrollController();
    _scrollController.addListener(_scrollListener);
    configManager.addListener(_onConfigChanged);
    ThemeManager.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    
    configManager.removeListener(_onConfigChanged);
    ThemeManager.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onConfigChanged(String key, dynamic value) {
    if (key == 'game_directory') {
      _modManager.refreshWorkshopPath();
      if (_tabController.index == 0) {
        _loadMods();
      } else {
        _loadLocalMods();
      }
    }
  }
  
  // 滚动监听器，控制回到顶部按钮的显示
  void _scrollListener() {
    setState(() {
      _showScrollTopButton = _scrollController.offset > 300;
    });
  }
  
  // 回到顶部
  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  

  

  

  // 获取模组启用状态（优先Bridge API）
  Future<bool> _getModEnabledStatus(String modId) async {
    return await _modManager.isModEnabled(modId);
  }

  Future<void> _loadMods() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 优先使用Bridge API混合模式加载
      final result = await _modManager.getSmartModsPaginated(
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
      // 回退到传统方法
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
      } catch (fallbackError) {
        print('[ModPage] 回退加载也失败: $fallbackError');
        setState(() {
          _isLoading = false;
        });
        showErrorDialog(context, '加载模组失败: $e');
      }
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
      showErrorDialog(context, '加载本地模组失败: $e');
    }
  }

  

  

  

  

  




  // Bridge API 状态指示器

  // Bridge API 状态横幅

  // 同步状态横幅

  // Bridge 同步进度条







  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeManager.getThemeColor('surface'),
      appBar: AppBar(
        backgroundColor: ThemeManager.getThemeColor('surface'),
        title: Text(
          '模组管理',
          style: TextStyle(color: ThemeManager.getThemeColor('text_primary')),
        ),
        bottom: TabBar(
          controller: _tabController,
          onTap: _onTabChanged,
          tabs: [
            Tab(icon: const Icon(Icons.store), child: Text('创意工坊', style: TextStyle(color: ThemeManager.getThemeColor('text_primary')))),
            Tab(icon: const Icon(Icons.folder), child: Text('本地模组', style: TextStyle(color: ThemeManager.getThemeColor('text_primary')))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_tabController.index == 0) {
                _loadMods();
              } else {
                _loadLocalMods();
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          
          // 搜索和排序控件 - 减小内边距和间距
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SearchBarCompact(
                    value: _searchQuery,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                        _applyFilters();
                      });
                    },
                    onClear: () {
                      setState(() {
                        _searchQuery = '';
                        _applyFilters();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SortControls(
                    sortBy: _sortBy,
                    onChangeSortBy: (value) {
                      setState(() {
                        _sortBy = value;
                        _applyFilters();
                      });
                    },
                    sortReverse: _sortReverse,
                    onToggleReverse: () {
                      setState(() {
                        _sortReverse = !_sortReverse;
                        _applyFilters();
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // 模组列表
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                WorkshopModsView(
                  isLoading: _isLoading,
                  filteredMods: _filteredMods,
                  scrollController: _scrollController,
                  selectAll: _selectAll,
                  onToggleSelectAll: _toggleSelectAll,
                  selectedModIds: _selectedModIds,
                  getEnabledStatus: _getModEnabledStatus,
                  onToggleSelect: _toggleModSelection,
                  onToggleStatus: _toggleModStatus,
                  onShowDetails: (m) => showModDetailsDialog(context, m),
                  onEnableSelected: _enableSelectedMods,
                  onDisableSelected: _disableSelectedMods,
                  currentPage: _currentPage,
                  totalPages: _totalPages,
                  onPrevPage: _currentPage > 1
                      ? () {
                          setState(() {
                            _currentPage--;
                            _loadMods();
                            _scrollToTop();
                          });
                        }
                      : null,
                  onNextPage: _currentPage < _totalPages
                      ? () {
                          setState(() {
                            _currentPage++;
                            _loadMods();
                            _scrollToTop();
                          });
                        }
                      : null,
                ),
                LocalModsView(
                  isLoading: _isLoadingLocal,
                  filteredMods: _filteredMods,
                  localMods: _localMods,
                  scrollController: _scrollController,
                  sortBy: _sortBy,
                  sortReverse: _sortReverse,
                  onChangeSortBy: (value) {
                    setState(() {
                      _sortBy = value;
                      _applyFilters();
                    });
                  },
                  onToggleReverse: () {
                    setState(() {
                      _sortReverse = !_sortReverse;
                      _applyFilters();
                    });
                  },
                  selectedModIds: _selectedModIds,
                  getEnabledStatus: _getModEnabledStatus,
                  onToggleSelect: _toggleModSelection,
                  onToggleStatus: _toggleModStatus,
                  onShowDetails: (m) => showModDetailsDialog(context, m),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _showScrollTopButton
          ? FloatingActionButton(
              onPressed: _scrollToTop,
              child: Icon(Icons.arrow_upward),
              tooltip: '回到顶部',
            )
          : null,
    );
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedModIds.clear();
      _selectAll = false;
      _searchQuery = '';
    });
    if (index == 0) {
      if (_mods.isEmpty) {
        _loadMods();
      } else {
        _applyFilters();
      }
    } else if (index == 1) {
      if (_localMods.isEmpty) {
        _loadLocalMods();
      } else {
        _applyFilters();
      }
    }
  }

  void _applyFilters() {
    List<LocalModInfo> filtered;
    if (_tabController.index == 0) {
      filtered = List.from(_mods);
    } else {
      filtered = List.from(_localMods);
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((mod) =>
          mod.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          mod.description.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }
    filtered = _modManager.sortMods(filtered, _sortBy, reverse: _sortReverse);
    setState(() {
      _filteredMods = filtered;
    });
  }

  void _toggleSelectAll(bool? value) {
    setState(() {
      _selectAll = value ?? false;
      if (_selectAll) {
        _selectedModIds = _filteredMods.map((mod) => mod.id).toSet();
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
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await _modManager.batchEnableMods(_selectedModIds.toList());
      final successCount = results.values.where((result) => result).length;
      showSuccessDialog(context, '成功启用 $successCount/${_selectedModIds.length} 个模组', onOk: _loadMods);
      setState(() {
        _selectedModIds.clear();
        _selectAll = false;
      });
      _loadMods();
    } catch (e) {
      showErrorDialog(context, '启用模组失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _disableSelectedMods() async {
    if (_selectedModIds.isEmpty) return;
    setState(() {
      _isLoading = true;
    });
    try {
      final results = await _modManager.batchDisableMods(_selectedModIds.toList());
      final successCount = results.values.where((result) => result).length;
      showSuccessDialog(context, '成功禁用 $successCount/${_selectedModIds.length} 个模组', onOk: _loadMods);
      setState(() {
        _selectedModIds.clear();
        _selectAll = false;
      });
      _loadMods();
    } catch (e) {
      showErrorDialog(context, '禁用模组失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleModStatus(String modId) async {
    try {
      final isEnabled = await _getModEnabledStatus(modId);
      final success = isEnabled
          ? await _modManager.disableMod(modId)
          : await _modManager.enableMod(modId);
      if (success) {
        showSuccessDialog(context, isEnabled ? '模组已禁用' : '模组已启用', onOk: _loadMods);
        _loadMods();
      } else {
        showErrorDialog(context, '操作失败');
      }
    } catch (e) {
      showErrorDialog(context, '操作失败: $e');
    }
  }
}

/// 便捷函数 - 创建模组页面视图
Widget modsPageView() {
  return const ModPage();
}
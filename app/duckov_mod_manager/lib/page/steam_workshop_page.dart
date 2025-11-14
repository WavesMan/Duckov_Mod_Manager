// steam_workshop_page.dart
/// Steam创意工坊页面 - 对应Python版本的SteamWorkshopPage功能重构

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/theme_manager.dart';
import '../services/steam_workshop_service.dart';
import '../services/mod_manager.dart';
import '../services/config_manager.dart';
import '../services/preload_manager.dart';

class SteamWorkshopPage extends StatefulWidget {
  const SteamWorkshopPage({Key? key}) : super(key: key);

  @override
  SteamWorkshopPageState createState() => SteamWorkshopPageState();
}

class SteamWorkshopPageState extends State<SteamWorkshopPage> {
  final SteamWorkshopService _service = SteamWorkshopService();
  final PreloadManager _preloadManager = PreloadManager();
  final String _appId = "3167020"; // Duckov Game的App ID
  
  // 滚动控制器
  final ScrollController _scrollController = ScrollController();
  
  // 预加载数据存储（用于存储额外的预加载数据）
  final Map<String, Map<int, Map<String, dynamic>>> _additionalPreloadedData = {
    'most_popular': {},
    'top_rated': {},
    'newest': {},
    'last_updated': {}
  };
  
  // 当前显示的数据
  Map<String, dynamic> _currentData = {
    'items': [],
    'current_page': 1,
    'total_pages': 1,
    'sort_by': 'most_popular',
    'search_term': ''
  };
  
  // UI状态
  final TextEditingController _searchController = TextEditingController();
  String _selectedSort = 'most_popular';
  bool _isLoading = false;
  bool _isReloading = false; // 用于控制刷新动画
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    
    // 监听滚动事件，用于控制回到顶部按钮的显示
    _scrollController.addListener(_scrollListener);
  }
  
  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }
  
  // 滚动监听器
  void _scrollListener() {
    // 滚动监听逻辑可以根据需要添加
  }
  
  // 回到顶部
  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }
  
  Future<void> _loadInitialData({bool isRefresh = false}) async {
    setState(() {
      if (isRefresh) {
        _isReloading = true;
      } else {
        _isLoading = true;
      }
      _errorMessage = null;
    });
    
    try {
      // 如果是刷新操作，清除缓存数据
      if (isRefresh) {
        _additionalPreloadedData.clear();
        _additionalPreloadedData.addAll({
          'most_popular': {},
          'top_rated': {},
          'newest': {},
          'last_updated': {}
        });
        
        // 清除预加载管理器中的数据
        _preloadManager.clearPreloadedData();
      }
      
      // 首先检查预加载管理器是否有数据
      final preloadedResult = _preloadManager.getPreloadedData(
        _currentData['sort_by'], 
        _currentData['current_page']
      );
      
      if (preloadedResult != null && !isRefresh) {
        // 使用预加载数据
        setState(() {
          _currentData = {
            'items': preloadedResult['items'],
            'current_page': preloadedResult['current_page'],
            'total_pages': preloadedResult['total_pages'],
            'sort_by': _currentData['sort_by'],
            'search_term': _currentData['search_term']
          };
        });
        print('[SteamWorkshopPage] 使用预加载数据: ${_currentData['sort_by']} 第${_currentData['current_page']}页');
      } else {
        // 没有预加载数据，从网络加载
        final result = await _service.getWorkshopItems(
          _appId, 
          _currentData['sort_by'], 
          _currentData['search_term'], 
          _currentData['current_page']
        );
        
        if (result != null) {
          setState(() {
            _currentData = {
              'items': result['items'],
              'current_page': result['current_page'],
              'total_pages': result['total_pages'],
              'sort_by': _currentData['sort_by'],
              'search_term': _currentData['search_term']
            };
          });
        } else {
          setState(() {
            _errorMessage = '无法加载创意工坊数据';
          });
          return;
        }
      }
      
      // 开始智能预加载
      _smartPreload(_currentData['sort_by'], _currentData['current_page'], _currentData['total_pages']);
      
    } catch (e) {
      setState(() {
        _errorMessage = '加载数据时出错: $e';
      });
    } finally {
      setState(() {
        if (isRefresh) {
          _isReloading = false;
        } else {
          _isLoading = false;
        }
      });
    }
  }
  
  void _smartPreload(String sortBy, int currentPage, int totalPages) {
    // 预加载后续页面数据
    if (currentPage < totalPages) {
      for (int i = 1; i <= 3; i++) {
        final nextPage = currentPage + i;
        if (nextPage <= totalPages) {
          // 检查预加载管理器是否已经有数据
          if (!_preloadManager.isPreloaded(sortBy, nextPage)) {
            _preloadPage(sortBy, nextPage);
          }
        }
      }
    }
  }
  
  Future<void> _preloadPage(String sortBy, int pageNum) async {
    // 检查是否已经预加载过（包括预加载管理器和额外预加载数据）
    if (_preloadManager.isPreloaded(sortBy, pageNum) || 
        _additionalPreloadedData[sortBy]?.containsKey(pageNum) == true) {
      return;
    }
    
    try {
      final result = await _service.getWorkshopItems(_appId, sortBy, '', pageNum);
      if (result != null) {
        setState(() {
          _additionalPreloadedData[sortBy]![pageNum] = result;
        });
        print('[SteamWorkshopPage] 预加载完成: $sortBy 第$pageNum页');
      }
    } catch (e) {
      print('[SteamWorkshopPage] 预加载失败 $sortBy 第$pageNum页: $e');
    }
  }
  
  Future<void> _onSearch() async {
    final searchTerm = _searchController.text.trim();
    setState(() {
      _currentData['search_term'] = searchTerm;
      _currentData['current_page'] = 1;
    });
    await _loadInitialData();
  }
  
  Future<void> _onSortChange(String? newSort) async {
    if (newSort != null && newSort != _selectedSort) {
      setState(() {
        _selectedSort = newSort;
        _currentData['sort_by'] = newSort;
        _currentData['current_page'] = 1;
      });
      await _loadInitialData();
    }
  }
  
  Future<void> _onPageChange(int newPage) async {
    // 首先检查预加载管理器是否有数据
    final preloadedResult = _preloadManager.getPreloadedData(_currentData['sort_by'], newPage);
    
    if (preloadedResult != null) {
      // 使用预加载管理器中的数据
      setState(() {
        _currentData = {
          'items': preloadedResult['items'],
          'current_page': newPage,
          'total_pages': preloadedResult['total_pages'],
          'sort_by': _currentData['sort_by'],
          'search_term': _currentData['search_term']
        };
      });
      print('[SteamWorkshopPage] 使用预加载数据切换页面: ${_currentData['sort_by']} 第$newPage页');
      
      // 智能预加载后续页面
      _smartPreload(_currentData['sort_by'], newPage, _currentData['total_pages']);
    } else {
      // 检查额外的预加载数据
      if (_additionalPreloadedData[_currentData['sort_by']]?.containsKey(newPage) == true) {
        setState(() {
          _currentData = {
            'items': _additionalPreloadedData[_currentData['sort_by']]![newPage]!['items'],
            'current_page': newPage,
            'total_pages': _additionalPreloadedData[_currentData['sort_by']]![newPage]!['total_pages'],
            'sort_by': _currentData['sort_by'],
            'search_term': _currentData['search_term']
          };
        });
        
        // 智能预加载后续页面
        _smartPreload(_currentData['sort_by'], newPage, _currentData['total_pages']);
      } else {
        setState(() {
          _currentData['current_page'] = newPage;
        });
        await _loadInitialData();
      }
    }
  }
  
  Future<void> _openModUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('无法打开链接: $url'),
          backgroundColor: ThemeManager.getThemeColor('error'),
        )
      );
    }
  }
  
  Future<bool> _checkModInstalled(String modId) async {
    final modManager = Provider.of<ModManager>(context, listen: false);
    return await modManager.isModDownloaded(modId);
  }
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          // 这层就是铺满 layout 区的背景
          color: ThemeManager.getThemeColor('surface'),
          child: SingleChildScrollView(
            controller: _scrollController,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: constraints.maxWidth,
                minHeight: constraints.maxHeight,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 800, // 保持中间内容区域最大宽度
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeader(),
                        SizedBox(height: 20),
                        bodyText('浏览和下载Steam创意工坊的模组。'),
                        SizedBox(height: 30),
                        
                        // 搜索和排序控件
                        _buildSearchControls(),
                        SizedBox(height: 20),
                        
                        // 加载状态和错误信息
                        if (_isLoading || _isReloading) _buildLoadingIndicator(),
                        if (_errorMessage != null) _buildErrorMessage(),
                        
                        // 模组列表
                        if (!_isLoading && !_isReloading && _errorMessage == null)
                          AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            switchInCurve: Curves.easeIn,
                            switchOutCurve: Curves.easeOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: child,
                              );
                            },
                            child: _buildModsGrid(),
                          ),
                        
                        // 分页控件
                        if (!_isLoading && !_isReloading && _errorMessage == null && _currentData['total_pages'] > 1) 
                          _buildPaginationControls(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildSearchControls() {
    return Row(
      children: [
        // 搜索框
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: '搜索模组...',
              labelStyle: TextStyle(color: ThemeManager.getThemeColor('text_secondary')),
              prefixIcon: Icon(Icons.search, color: ThemeManager.getThemeColor('text_secondary')),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ThemeManager.getThemeColor('text_secondary')),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ThemeManager.getThemeColor('text_secondary')),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: ThemeManager.getThemeColor('primary')),
              ),
            ),
            style: TextStyle(color: ThemeManager.getThemeColor('text_primary')),
            onSubmitted: (_) => _onSearch(),
          ),
        ),
        SizedBox(width: 10),
        
        // 排序下拉框
        DropdownButton<String>(
          value: _selectedSort,
          items: [
            DropdownMenuItem(value: 'most_popular', child: Text('最热门', style: TextStyle(color: ThemeManager.getThemeColor('text_primary')))),
            DropdownMenuItem(value: 'top_rated', child: Text('最高评分', style: TextStyle(color: ThemeManager.getThemeColor('text_primary')))),
            DropdownMenuItem(value: 'newest', child: Text('最新', style: TextStyle(color: ThemeManager.getThemeColor('text_primary')))),
            DropdownMenuItem(value: 'last_updated', child: Text('最近更新', style: TextStyle(color: ThemeManager.getThemeColor('text_primary')))),
          ],
          onChanged: _onSortChange,
          dropdownColor: ThemeManager.getThemeColor('surface'),
        ),
        SizedBox(width: 10),
        
        // 搜索按钮
        ElevatedButton.icon(
          onPressed: _onSearch,
          icon: Icon(Icons.search),
          label: Text('搜索'),
        ),
      ],
    );
  }
  
  Widget _buildLoadingIndicator() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10),
            Text(
                '正在加载创意工坊数据...',
                style: TextStyle(
                  color: ThemeManager.getThemeColor('text_primary'),
                ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildErrorMessage() {
    return Container(
      color: ThemeManager.getThemeColor('surface'),
      width: double.infinity,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeManager.getThemeColor('error').withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(Icons.error, color: ThemeManager.getThemeColor('error'), size: 40),
          SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: TextStyle(color: ThemeManager.getThemeColor('error')),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: _loadInitialData,
            child: Text('重试'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildModsGrid() {
    final items = _currentData['items'] as List<dynamic>;
    
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(Icons.search_off, size: 60, color: ThemeManager.getThemeColor('text_secondary')),
              SizedBox(height: 10),
              Text(
                _currentData['search_term'].isEmpty 
                  ? '暂无模组数据' 
                  : '未找到匹配的模组',
                style: ThemeManager.bodyTextStyle(size: 16),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        headingText(
          _getSortDisplayName(_currentData['sort_by']),
          level: 2,
        ),
        SizedBox(height: 16),
        // 使用网格视图实现两列瀑布流布局
        LayoutBuilder(
          builder: (context, constraints) {
            final cardWidth = (constraints.maxWidth - 16) / 2; // 计算卡片宽度
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 2.5, // 保持原始比例作为fallback
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final mod = items[index];
                return SizedBox(
                  height: 220, // 设置固定高度
                  child: _buildModCard(mod),
                );
              },
            );
          }
        ),
      ],
    );
  }
  
  Widget _buildModCard(Map<String, dynamic> mod) {
    return FutureBuilder<bool>(
      future: _checkModInstalled(mod['id'] ?? ''),
      builder: (context, snapshot) {
        final isSubscribed = snapshot.data ?? false;
        
        return Card(
          elevation: 3,
          color: ThemeManager.getThemeColor('background'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => _openModUrl(mod['url'] ?? ''),
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
                        // 模组标题
                        Text(
                          mod['name'] ?? '未知模组',
                          style: ThemeManager.headingTextStyle(level: 5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // 作者信息
                        Text(
                          '作者: ${mod['author'] ?? '未知'}',
                          style: ThemeManager.bodyTextStyle(size: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        
                        const SizedBox(height: 6),
                        
                        // 统计信息和状态
                        _buildModStats(mod, isSubscribed),
                        
                        const SizedBox(height: 6),
                        
                        // 描述文本（滚动）
                        Expanded(
                          child: _buildModDescription(mod),
                        ),
                      ],
                    ),
                  ),
                  
                  // 右侧：按钮列
                  Container(
                    width: 100,
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 查看详情按钮
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => _openModUrl(mod['url'] ?? ''),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: const Text('详情', style: TextStyle(fontSize: 17)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // 订阅按钮
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openModUrl(mod['url'] ?? ''),
                            icon: Icon(isSubscribed ? Icons.check_circle : Icons.add, size: 16),
                            label: Text(isSubscribed ? '已订阅' : '订阅', style: const TextStyle(fontSize: 17)),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide(color: isSubscribed ? Colors.green : Colors.orange),
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
  
  Widget _buildModPreview(Map<String, dynamic> mod) {
    final previewUrl = mod['preview_url'] ?? '';
    
    if (previewUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          previewUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: ThemeManager.getThemeColor('surface'),
              ),
              child: Icon(Icons.extension, size: 40, color: ThemeManager.getThemeColor('text_secondary')),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: ThemeManager.getThemeColor('surface'),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                      : null,
                  valueColor: AlwaysStoppedAnimation<Color>(ThemeManager.getThemeColor('primary')),
                ),
              ),
            );
          },
        ),
      );
    } else {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: ThemeManager.getThemeColor('surface'),
        ),
        child: Icon(Icons.extension, size: 40, color: ThemeManager.getThemeColor('text_secondary')),
      );
    }
  }
  
  Widget _buildModDescription(Map<String, dynamic> mod) {
    final description = mod['description'] ?? '暂无描述';
    
    return SingleChildScrollView(
      child: Text(
        description,
        style: ThemeManager.bodyTextStyle(size: 11),
      ),
    );
  }

  Widget _buildModStats(Map<String, dynamic> mod, bool isSubscribed) {
    return Row(
      children: [
        // 评分
        if ((mod['rating'] ?? 0) > 0) ...[
          Icon(Icons.star, size: 12, color: Colors.orange),
          SizedBox(width: 2),
          Text(
            '${mod['rating']}',
            style: ThemeManager.bodyTextStyle(size: 12),
          ),
          SizedBox(width: 16),
        ],
        
        // 订阅数
        if ((mod['subscriptions'] ?? 0) > 0) ...[
          Icon(Icons.people, size: 12, color: ThemeManager.getThemeColor('primary')),
          SizedBox(width: 2),
          Text(
            '${mod['subscriptions']}',
            style: ThemeManager.bodyTextStyle(size: 12),
          ),
          SizedBox(width: 16),
        ],
        
        // 文件大小（如果有）
        if ((mod['file_size'] ?? '').isNotEmpty) ...[
          Icon(Icons.storage, size: 12, color: ThemeManager.getThemeColor('success')),
          SizedBox(width: 2),
          Text(
            mod['file_size'],
            style: ThemeManager.bodyTextStyle(size: 12),
          ),
          SizedBox(width: 16),
        ],
        
        // 本地状态指示器
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isSubscribed 
                ? ThemeManager.getThemeColor('primary').withOpacity(0.3) 
                : ThemeManager.getThemeColor('surface'),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            isSubscribed ? '本地已下载' : '需订阅',
            style: TextStyle(
              fontSize: 10,
              color: isSubscribed 
                  ? ThemeManager.getThemeColor('primary') 
                  : ThemeManager.getThemeColor('text_secondary'),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButtons(Map<String, dynamic> mod, bool isSubscribed) {
    return Row(
      children: [
        // 查看详情按钮
        OutlinedButton(
          onPressed: () => _openModUrl(mod['url'] ?? ''),
          child: Text('查看详情'),
        ),
        SizedBox(width: 8),
        
        // 订阅按钮 - 跳转到Steam创意工坊页面
        ElevatedButton.icon(
          onPressed: () => _openModUrl(mod['url'] ?? ''),
          icon: Icon(isSubscribed ? Icons.check : Icons.add),
          label: Text(isSubscribed ? '已订阅' : '前往订阅'),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSubscribed ? Colors.green : null,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPaginationControls() {
    final currentPage = _currentData['current_page'];
    final totalPages = _currentData['total_pages'];
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 上一页按钮
            IconButton(
              onPressed: currentPage > 1 ? () => _onPageChange(currentPage - 1) : null,
              icon: Icon(Icons.chevron_left, color: ThemeManager.getThemeColor('text_primary')),
            ),
            
            // 页码显示
            Text('第 $currentPage 页 / 共 $totalPages 页', style: ThemeManager.bodyTextStyle()),
            
            // 下一页按钮
            IconButton(
              onPressed: currentPage < totalPages ? () => _onPageChange(currentPage + 1) : null,
              icon: Icon(Icons.chevron_right, color: ThemeManager.getThemeColor('text_primary')),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getSortDisplayName(String sortBy) {
    switch (sortBy) {
      case 'most_popular': return '最热门模组';
      case 'top_rated': return '最高评分模组';
      case 'newest': return '最新模组';
      case 'last_updated': return '最近更新模组';
      default: return '模组列表';
    }
  }

  /// 构建页面头部，包含标题和刷新按钮
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        headingText('创意工坊', level: 1),
        IconButton(
          icon: Icon(Icons.refresh, color: ThemeManager.getThemeColor('text_primary')),
          onPressed: () async {
            await _loadInitialData(isRefresh: true);
          },
          tooltip: '刷新',
          color: ThemeManager.getThemeColor('text_primary'),
        ),
      ],
    );
  }
}

/// 便捷函数 - 创建创意工坊页面视图
Widget steamWorkshopView() {
  return SteamWorkshopPage();
}
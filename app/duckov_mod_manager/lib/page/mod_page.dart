// mod_page.dart
/// 模组管理页面 - 基于Flet的mods_page.py重构

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/mod_manager.dart';
import '../services/theme_manager.dart';
import '../services/bridge_sync_service.dart';

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
  final ScrollController _scrollController = ScrollController();
  bool _showScrollTopButton = false;
  
  // Bridge API 相关状态
  bool _isBridgeConnected = false;
  bool _isCheckingBridgeConnection = false;
  Timer? _bridgeStatusTimer;
  final Map<String, Future<bool>> _modStatusFutures = {};
  
  // 防重复提示相关状态
  DateTime? _lastShowErrorDialogTime;
  DateTime? _lastShowSuccessDialogTime;
  final Duration _dialogCooldown = Duration(seconds: 5); // 对话框冷却时间
  
  // 自动重连相关状态
  Timer? _autoReconnectTimer;
  int _consecutiveFailureCount = 0;
  DateTime? _lastConnectionCheckTime;
  
  // Bridge 同步服务相关状态
  BridgeSyncService? _bridgeSyncService;
  bool _isSyncInProgress = false;
  String _syncProgressText = '';
  double _syncProgress = 0.0;
  
  // 同步状态显示
  String _lastSyncResult = '';
  bool _showSyncSuccess = false;


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
    
    // 启动Bridge连接状态监控
    _startBridgeStatusMonitoring();
    
    // 初始化Bridge同步服务
    _initBridgeSyncService();
    
    // 添加滚动监听器
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _bridgeStatusTimer?.cancel();
    _autoReconnectTimer?.cancel();
    _modStatusFutures.clear();
    _bridgeSyncService?.dispose();
    super.dispose();
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

  // Bridge API 连接状态监控
  void _startBridgeStatusMonitoring() {
    _checkBridgeConnection();
    _bridgeStatusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _checkBridgeConnection();
    });
  }

  // Bridge 连接状态变化处理
  void _onBridgeConnectionChanged(bool isConnected) {
    print('[ModPage]Bridge连接状态变化: ${isConnected ? "已连接" : "已断开"}');
    
    setState(() {
      _isBridgeConnected = isConnected;
    });
    
    // 不管连接还是断开，都清空缓存以确保数据一致性
    print('[ModPage]清空缓存以确保数据一致性');
    _modManager.invalidateCache(); // 清空缓存
    
    if (isConnected) {
      print('[ModPage]Bridge连接恢复，重新加载模组');
      _loadMods(); // 重新加载模组数据
    } else {
      print('[ModPage]Bridge连接断开，切换到本地模式并重新加载模组');
      _loadMods(); // 重新加载模组数据（使用本地模式）
      
      // 断开时启动自动重连机制
      _startAutoReconnect();
    }
  }

  // 检查Bridge连接状态（带防抖和重复提示防护）
  Future<void> _checkBridgeConnection() async {
    if (_isCheckingBridgeConnection) return;
    
    setState(() {
      _isCheckingBridgeConnection = true;
    });

    try {
      final isConnected = await _modManager.isBridgeConnected();
      if (mounted) {
        final wasDisconnected = !_isBridgeConnected && isConnected;
        final wasConnected = _isBridgeConnected && !isConnected;
        
        setState(() {
          _isBridgeConnected = isConnected;
          _isCheckingBridgeConnection = false;
        });
        
        // 连接状态变化提示（防止重复提示）
        if (wasConnected) {
          print('[ModPage] Bridge连接恢复，停止自动重连');
          _stopAutoReconnect(); // 停止自动重连
          // 只有在3秒后才显示恢复提示，避免页面切换时的误判
          _showSuccessDialogOnce('Bridge API 连接已恢复');
          _onBridgeConnectionChanged(true);
        } else if (wasDisconnected) {
          // 只有在连续多次失败后才显示断开提示
          _showErrorDialogOnce('Bridge API 连接已断开，将使用文件系统模式');
          _onBridgeConnectionChanged(false);
        }
      }
    } catch (e) {
      print('[ModPage] Bridge连接检查失败: $e');
      if (mounted) {
        final wasConnected = _isBridgeConnected;
        setState(() {
          _isBridgeConnected = false;
          _isCheckingBridgeConnection = false;
        });
        
        // 如果之前连接成功，现在失败了，显示错误提示
        if (wasConnected) {
          _showErrorDialogOnce('Bridge API 连接错误: $e，已切换到文件系统模式');
        }
      }
    }
  }

  // 手动重连Bridge API
  Future<void> _reconnectBridge() async {
    setState(() {
      _isCheckingBridgeConnection = true;
    });

    try {
      // 尝试重新初始化Bridge连接
      await _modManager.initializeBridgeConnection();
      await _checkBridgeConnection();
    } catch (e) {
      setState(() {
        _isCheckingBridgeConnection = false;
      });
      _showErrorDialog('Bridge API 重连失败: $e');
    }
  }

  // 初始化Bridge同步服务
  void _initBridgeSyncService() {
    try {
      _bridgeSyncService = BridgeSyncService(
        _modManager.bridgeClient,
        _modManager,
      );
      
      // 设置进度回调
      _bridgeSyncService!.setProgressCallback((status, progress, message) {
        if (mounted) {
          setState(() {
            _isSyncInProgress = status is SyncStatusStarted || 
                                status is SyncStatusReadingLocal || 
                                status is SyncStatusReadingRemote || 
                                status is SyncStatusCalculating ||
                                (status is SyncStatusEnabling) ||
                                (status is SyncStatusDisabling);
            _syncProgress = progress;
            _syncProgressText = message;
            
            // 处理同步完成和错误状态
            if (status is SyncStatusCompleted) {
              final result = '同步完成 - 成功: ${status.success}, 失败: ${status.failed}';
              _lastSyncResult = result;
              _showSyncSuccess = true;
              
              // 3秒后隐藏成功消息
              Timer(const Duration(seconds: 3), () {
                if (mounted) {
                  setState(() {
                    _showSyncSuccess = false;
                  });
                }
              });
            } else if (status is SyncStatusError) {
              _lastSyncResult = '同步失败: ${status.message}';
              _showSyncSuccess = false;
            }
          });
        }
      });
      
      _bridgeSyncService!.start();
      print('[ModPage] Bridge同步服务已启动');
    } catch (e) {
      print('[ModPage] Bridge同步服务初始化失败: $e');
    }
  }

  // 手动触发Bridge同步
  Future<void> _triggerManualSync() async {
    if (_bridgeSyncService == null || !_isBridgeConnected) {
      _showErrorDialog('Bridge API 未连接，无法同步');
      return;
    }

    if (_isSyncInProgress) {
      _showErrorDialog('同步正在进行中，请稍候');
      return;
    }

    try {
      await _bridgeSyncService!.forceSync();
      _showSuccessDialog('手动同步完成');
    } catch (e) {
      _showErrorDialog('手动同步失败: $e');
    }
  }

  // 获取模组启用状态（优先Bridge API）
  Future<bool> _getModEnabledStatus(String modId) {
    if (_modStatusFutures.containsKey(modId)) {
      return _modStatusFutures[modId]!;
    }

    final future = _modManager.isModEnabled(modId);
    _modStatusFutures[modId] = future;
    
    future.then((_) {
      _modStatusFutures.remove(modId);
    }).catchError((_) {
      _modStatusFutures.remove(modId);
    });

    return future;
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
        _showErrorDialog('加载模组失败: $e');
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
    if (index == 0) {
      if (_mods.isEmpty) {
        _loadMods();
      } else {
        // 确保总是重新应用过滤器以显示正确的数据
        _applyFilters();
      }
    } else if (index == 1) {
      if (_localMods.isEmpty) {
        _loadLocalMods();
      } else {
        // 确保总是重新应用过滤器以显示正确的数据
        _applyFilters();
      }
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
      // 清除状态缓存
      _modStatusFutures.clear();
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

  // 防重复错误对话框
  void _showErrorDialogOnce(String message) {
    final now = DateTime.now();
    // 检查是否需要冷却
    if (_lastShowErrorDialogTime != null && 
        now.difference(_lastShowErrorDialogTime!) < _dialogCooldown) {
      print('[ModPage] 错误对话框冷却中，跳过显示: $message');
      return;
    }

    // 更新最后显示时间
    _lastShowErrorDialogTime = now;
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

  // 防重复成功对话框
  void _showSuccessDialogOnce(String message) {
    final now = DateTime.now();
    // 检查是否需要冷却
    if (_lastShowSuccessDialogTime != null && 
        now.difference(_lastShowSuccessDialogTime!) < _dialogCooldown) {
      print('[ModPage] 成功对话框冷却中，跳过显示: $message');
      return;
    }

    // 更新最后显示时间
    _lastShowSuccessDialogTime = now;
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

  // 自动重连机制
  void _startAutoReconnect() {
    print('[ModPage] 启动自动重连机制');
    
    // 取消之前的自动重连定时器
    _autoReconnectTimer?.cancel();
    
    // 重置连续失败计数
    _consecutiveFailureCount = 0;
    
    // 设置自动重连定时器：每3秒尝试一次，最多尝试5次
    _autoReconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_consecutiveFailureCount >= 5) {
        print('[ModPage] 自动重连达到最大尝试次数，停止重连');
        timer.cancel();
        return;
      }
      
      _consecutiveFailureCount++;
      print('[ModPage] 自动重连尝试 ${_consecutiveFailureCount}/5');
      
      try {
        // 检查连接状态
        final isConnected = await _modManager.isBridgeConnected();
        if (isConnected) {
          print('[ModPage] 自动重连成功');
          timer.cancel();
          _consecutiveFailureCount = 0;
          _isBridgeConnected = true;
          // 重新加载模组列表
          _loadMods();
        } else {
          print('[ModPage] 自动重连失败，将在下个周期重试');
        }
      } catch (e) {
        print('[ModPage] 自动重连过程出错: $e');
      }
    });
  }

  // 停止自动重连机制
  void _stopAutoReconnect() {
    print('[ModPage] 停止自动重连机制');
    _autoReconnectTimer?.cancel();
    _consecutiveFailureCount = 0;
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

    setState(() {
      _isLoading = true;
    });

    try {
      // 优先使用Bridge API批量操作
      final results = _isBridgeConnected
          ? await _modManager.batchToggleBridgeMods(_selectedModIds, true)
          : await _modManager.batchEnableMods(_selectedModIds);
      
      final successCount = results.values.where((result) => result).length;
      
      _showSuccessDialog('成功启用 $successCount/${_selectedModIds.length} 个模组');
      setState(() {
        _selectedModIds.clear();
        _selectAll = false;
        _modStatusFutures.clear();
      });
      
      // 刷新模组列表以显示最新状态
      _loadMods();
    } catch (e) {
      _showErrorDialog('启用模组失败: $e');
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
      // 优先使用Bridge API批量操作
      final results = _isBridgeConnected
          ? await _modManager.batchToggleBridgeMods(_selectedModIds, false)
          : await _modManager.batchDisableMods(_selectedModIds);
      
      final successCount = results.values.where((result) => result).length;
      
      _showSuccessDialog('成功禁用 $successCount/${_selectedModIds.length} 个模组');
      setState(() {
        _selectedModIds.clear();
        _selectAll = false;
        _modStatusFutures.clear();
      });
      
      // 刷新模组列表以显示最新状态
      _loadMods();
    } catch (e) {
      _showErrorDialog('禁用模组失败: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleModStatus(String modId) async {
    try {
      setState(() {
        // 清除该模组的状态缓存
        _modStatusFutures.remove(modId);
      });

      final isEnabled = await _getModEnabledStatus(modId);
      bool success;
      
      if (_isBridgeConnected) {
        // 优先使用Bridge API
        success = isEnabled 
            ? await _modManager.disableBridgeMod(modId)
            : await _modManager.enableBridgeMod(modId);
      } else {
        // 回退到传统方法
        success = isEnabled 
            ? await _modManager.disableMod(modId)
            : await _modManager.enableMod(modId);
      }

      if (success) {
        _showSuccessDialog(isEnabled ? '模组已禁用' : '模组已启用');
        // 刷新模组列表以显示最新状态
        _loadMods();
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

  // Bridge API 状态指示器
  Widget _buildBridgeStatusIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isBridgeConnected ? Icons.link : Icons.link_off,
            color: _isBridgeConnected ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 4),
          Text(
            'Bridge',
            style: TextStyle(
              color: _isBridgeConnected ? Colors.green : Colors.red,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 添加重连按钮（当Bridge断开连接时显示）
          if (!_isBridgeConnected && !_isCheckingBridgeConnection) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: _reconnectBridge,
              icon: Icon(Icons.refresh, size: 30, color: Colors.orange[600]),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 20,
                minHeight: 20,
              ),
              tooltip: '重连Bridge API',
            ),
          ],
        ],
      ),
    );
  }

  // Bridge API 状态横幅
  Widget _buildBridgeStatusBanner() {
    if (_isBridgeConnected || _isCheckingBridgeConnection) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _isBridgeConnected 
              ? Colors.green.withOpacity(0.1)
              : Colors.orange.withOpacity(0.1),
          border: Border(
            bottom: BorderSide(
              color: _isBridgeConnected ? Colors.green : Colors.orange,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _isBridgeConnected ? Icons.check_circle : Icons.warning,
              color: _isBridgeConnected ? Colors.green : Colors.orange,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isBridgeConnected
                    ? 'Bridge API 已连接 - 实时模组管理可用'
                    : _isCheckingBridgeConnection
                        ? '正在检查Bridge API连接...'
                        : 'Bridge API 未连接 - 使用文件系统模式',
                style: TextStyle(
                  color: _isBridgeConnected ? Colors.green : Colors.orange,
                  fontSize: 12,
                ),
              ),
            ),
            if (!_isBridgeConnected && !_isCheckingBridgeConnection)
              TextButton(
                onPressed: _checkBridgeConnection,
                child: const Text('重试', style: TextStyle(fontSize: 12)),
              ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // 同步状态横幅
  Widget _buildSyncStatusBanner() {
    if (!_showSyncSuccess && _lastSyncResult.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final isSuccess = _lastSyncResult.contains('完成');
    final bgColor = isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1);
    final borderColor = isSuccess ? Colors.green : Colors.red;
    final textColor = isSuccess ? Colors.green[700] : Colors.red[700];
    final icon = isSuccess ? Icons.check_circle : Icons.error;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: borderColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lastSyncResult,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (!_showSyncSuccess) ...[
            const SizedBox(width: 4),
            IconButton(
              onPressed: () {
                setState(() {
                  _lastSyncResult = '';
                });
              },
              icon: Icon(Icons.close, size: 16, color: textColor),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              tooltip: '关闭',
            ),
          ],
        ],
      ),
    );
  }

  // Bridge 同步进度条
  Widget _buildSyncProgressBar() {
    if (!_isSyncInProgress) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(
            color: Colors.blue,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.sync,
                color: Colors.blue,
                size: 16,
              ),
              const SizedBox(width: 8),
              const Text(
                'Bridge 同步进行中',
                style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              if (_syncProgress > 0 && _syncProgress < 1.0)
                Text(
                  '${(_syncProgress * 100).toInt()}%',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          if (_syncProgressText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              _syncProgressText,
              style: TextStyle(
                color: Colors.blue[700],
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _syncProgress,
            backgroundColor: Colors.blue.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
        ],
      ),
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



  Widget _buildModCard(ModInfo mod) {
    final isSelected = _selectedModIds.contains(mod.id);

    return FutureBuilder<bool>(
      future: _getModEnabledStatus(mod.id),
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
                _scrollToTop(); // 切换页面时回到顶部
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
                _scrollToTop(); // 切换页面时回到顶部
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
        bottom: TabBar(
          controller: _tabController,
          onTap: _onTabChanged,
          tabs: const [
            Tab(text: '创意工坊', icon: Icon(Icons.store)),
            Tab(text: '本地模组', icon: Icon(Icons.folder)),
          ],
        ),
        actions: [
          // Bridge API 连接状态
          _buildBridgeStatusIndicator(),
          // 手动同步按钮
          IconButton(
            icon: Stack(
              children: [
                Icon(
                  Icons.sync,
                  color: _isBridgeConnected ? Colors.blue : Colors.grey,
                ),
                if (_isSyncInProgress)
                  Positioned.fill(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                  ),
              ],
            ),
            onPressed: _isBridgeConnected ? _triggerManualSync : null,
            tooltip: _isSyncInProgress ? '同步进行中...' : '手动同步到游戏',
          ),
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
          // Bridge API 状态横幅
          _buildBridgeStatusBanner(),
          // 同步状态横幅
          _buildSyncStatusBanner(),
          // 搜索和排序控件 - 减小内边距和间距
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(flex: 2, child: _buildSearchBar()),
                const SizedBox(width: 8),
                Expanded(child: _buildSortControls()),
              ],
            ),
          ),
          // Bridge 同步进度条
          _buildSyncProgressBar(),
          // 模组列表
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // 创意工坊模组页面
                _buildWorkshopModsPage(),
                // 本地模组页面
                _buildLocalModsPage(),
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

  Widget _buildWorkshopModsPage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 紧凑控制栏
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                // 全选控制
                Checkbox(
                  value: _selectAll,
                  onChanged: _toggleSelectAll,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                const Text('全选', style: TextStyle(fontSize: 12)),
                const Spacer(),
              ],
            ),
          ),
          
          // 紧凑批量操作控制
          _buildBatchControls(),
          
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
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // 添加边界检查以防止数组越界错误
                                if (index >= _filteredMods.length || _filteredMods.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final mod = _filteredMods[index];
                                return _buildModCard(mod);
                              },
                              childCount: _filteredMods.length,
                            )
                          ),
                          // 添加分页控件作为单独的sliver
                          SliverToBoxAdapter(
                            child: _buildPaginationControls(),
                          ),
                        ],
                      ),
          ),
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
                  '本地模组 (${_localMods.length})',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                // 搜索栏已移至顶部主界面
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
                    : CustomScrollView(
                        controller: _scrollController,
                        slivers: [
                          SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 3,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                // 添加边界检查以防止数组越界错误
                                if (index >= _filteredMods.length || _filteredMods.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final mod = _filteredMods[index];
                                return _buildModCard(mod);
                              },
                              childCount: _filteredMods.length,
                            )
                          )
                        ],
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
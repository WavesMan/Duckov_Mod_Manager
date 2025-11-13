// preload_manager.dart
/// 预加载管理器 - 负责应用启动时的数据预加载

import 'dart:io';
import 'dart:isolate';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'steam_workshop_service.dart';
import 'package:path/path.dart' as path;
import 'config_manager.dart';
import 'package:http/http.dart' as http;

class PreloadManager {
  static final PreloadManager _instance = PreloadManager._internal();
  
  factory PreloadManager() => _instance;
  
  PreloadManager._internal();
  
  final SteamWorkshopService _workshopService = SteamWorkshopService();
  final String _appId = "3167020"; // Duckov Game的App ID
  
  // 预加载状态
  bool _isPreloading = false;
  bool _isPreloaded = false;
  bool _isImagePreloading = false;
  
  // 预加载数据存储
  final Map<String, Map<int, Map<String, dynamic>>> _preloadedData = {
    'most_popular': {},
    'top_rated': {},
    'newest': {},
    'last_updated': {}
  };
  
  // HTTP客户端，支持缓存
  final http.Client _httpClient = http.Client();
  
  // 图片缓存存储
  final Set<String> _cachedImageUrls = {};
  
  // 预加载进度回调
  Function(int, int)? _onProgress;
  Function()? _onPreloadComplete;
  
  /// 开始预加载所有创意工坊数据
  Future<void> startPreloading({Function(int, int)? onProgress, Function()? onPreloadComplete}) async {
    if (_isPreloading || _isPreloaded) {
      return;
    }
    
    _isPreloading = true;
    _onProgress = onProgress;
    _onPreloadComplete = onPreloadComplete;
    
    try {
      await _preloadAllWorkshopData();
      _isPreloaded = true;
      print('[PreloadManager] 预加载完成: 所有创意工坊数据已准备就绪');
      
      // 页面预加载完成后立即通知UI可以进入主界面
      _onPreloadComplete?.call();
      
      // 后台进行图片预加载
      _preloadImagesInBackground();
    } catch (e) {
      print('[PreloadManager] 预加载失败: $e');
    } finally {
      _isPreloading = false;
    }
  }
  
  /// 预加载所有分类和页面的数据
  Future<void> _preloadAllWorkshopData() async {
    final sortMethods = ['most_popular', 'top_rated', 'newest', 'last_updated'];
    int totalTasks = sortMethods.length * 3; // 每个分类预加载3页
    int completedTasks = 0;
    
    // 使用Future.wait并行预加载，但限制并发数避免过多请求
    final List<Future<void>> futures = [];
    
    for (final sortMethod in sortMethods) {
      // 为每个分类预加载前3页
      for (int pageNum = 1; pageNum <= 3; pageNum++) {
        futures.add(_preloadSinglePage(sortMethod, pageNum).then((_) {
          completedTasks++;
          _onProgress?.call(completedTasks, totalTasks);
        }));
      }
    }
    
    // 分批执行，避免同时发起过多请求
    const batchSize = 4; // 每次最多4个并发请求
    for (int i = 0; i < futures.length; i += batchSize) {
      final batch = futures.sublist(i, i + batchSize > futures.length ? futures.length : i + batchSize);
      await Future.wait(batch);
      
      // 短暂延迟，避免请求过于密集
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }
  
  /// 预加载单个页面
  Future<void> _preloadSinglePage(String sortMethod, int pageNum) async {
    try {
      final result = await _workshopService.getWorkshopItems(_appId, sortMethod, '', pageNum);
      if (result != null) {
        _preloadedData[sortMethod]![pageNum] = result;
        print('[PreloadManager] 预加载完成: $sortMethod 第$pageNum页');
      }
    } catch (e) {
      print('[PreloadManager] 预加载失败 $sortMethod 第$pageNum页: $e');
      // 失败时重试一次
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final result = await _workshopService.getWorkshopItems(_appId, sortMethod, '', pageNum);
        if (result != null) {
          _preloadedData[sortMethod]![pageNum] = result;
          print('[PreloadManager] 重试预加载完成: $sortMethod 第$pageNum页');
        }
      } catch (e2) {
        print('[PreloadManager] 重试预加载失败 $sortMethod 第$pageNum页: $e2');
      }
    }
  }
  
  /// 在后台预加载图片
  Future<void> _preloadImagesInBackground() async {
    _isImagePreloading = true;
    try {
      await _preloadImages();
    } catch (e) {
      print('[PreloadManager] 图片预加载失败: $e');
    } finally {
      _isImagePreloading = false;
    }
  }
  
  /// 预加载图片
  Future<void> _preloadImages() async {
    print('[PreloadManager] 开始预加载图片');
    
    // 收集所有需要预加载的图片URL，避免重复
    final Set<String> imageURLs = <String>{};
    
    for (final sortMethod in _preloadedData.keys) {
      for (final pageNum in _preloadedData[sortMethod]!.keys) {
        final pageData = _preloadedData[sortMethod]![pageNum];
        if (pageData != null && pageData['items'] is List) {
          final items = pageData['items'] as List;
          for (final item in items) {
            if (item is Map<String, dynamic> && item['preview_url'] is String) {
              final imageUrl = item['preview_url'] as String;
              if (imageUrl.isNotEmpty && !_cachedImageUrls.contains(imageUrl)) {
                imageURLs.add(imageUrl);
              }
            }
          }
        }
      }
    }
    
    print('[PreloadManager] 需要预加载 ${imageURLs.length} 张不重复的图片');
    
    // 使用多线程并发下载图片
    final isolateCount = 6; // 使用6个并发线程
    final urlList = imageURLs.toList();
    final chunkSize = (urlList.length / isolateCount).ceil();
    
    final List<Future<void>> futures = [];
    for (int i = 0; i < urlList.length; i += chunkSize) {
      final end = (i + chunkSize < urlList.length) ? i + chunkSize : urlList.length;
      final chunk = urlList.sublist(i, end);
      futures.add(_downloadImageChunk(chunk));
    }
    
    await Future.wait(futures);
    print('[PreloadManager] 图片预加载完成');
  }
  
  /// 下载图片块
  Future<void> _downloadImageChunk(List<String> urls) async {
    for (final url in urls) {
      try {
        await _downloadAndCacheImage(url);
      } catch (e) {
        print('[PreloadManager] 下载图片失败 $url: $e');
      }
    }
  }
  
  /// 下载并缓存单张图片
  Future<void> _downloadAndCacheImage(String imageUrl) async {
    // 检查是否已经缓存过
    if (_cachedImageUrls.contains(imageUrl)) {
      return;
    }
    
    try {
      final uri = Uri.parse(imageUrl);
      final response = await _httpClient.get(uri);
      
      if (response.statusCode == 200) {
        // 记录已缓存的URL
        _cachedImageUrls.add(imageUrl);
        print('[PreloadManager] 图片缓存成功: $imageUrl');
      } else {
        print('[PreloadManager] 下载图片失败，状态码: ${response.statusCode}, URL: $imageUrl');
      }
    } catch (e) {
      print('[PreloadManager] 下载图片异常: $e, URL: $imageUrl');
    }
  }
  
  /// 获取预加载的数据
  Map<String, dynamic>? getPreloadedData(String sortMethod, int pageNum) {
    return _preloadedData[sortMethod]?[pageNum];
  }
  
  /// 检查是否已预加载指定数据
  bool isPreloaded(String sortMethod, int pageNum) {
    return _preloadedData[sortMethod]?.containsKey(pageNum) ?? false;
  }
  
  /// 检查预加载状态
  bool get isPreloading => _isPreloading;
  bool get allPreloaded => _isPreloaded;
  bool get isImagePreloading => _isImagePreloading;
  
  /// 获取预加载进度
  Map<String, int> getPreloadProgress() {
    int total = 0;
    int loaded = 0;
    
    for (final sortMethod in _preloadedData.keys) {
      total += 3; // 每个分类预加载3页
      loaded += _preloadedData[sortMethod]!.length;
    }
    
    return {
      'loaded': loaded,
      'total': total,
      'percentage': total > 0 ? (loaded / total * 100).round() : 0
    };
  }
  
  /// 清除预加载数据（用于重新加载）
  void clearPreloadedData() {
    for (final sortMethod in _preloadedData.keys) {
      _preloadedData[sortMethod]!.clear();
    }
    _cachedImageUrls.clear();
    _isPreloaded = false;
  }
  
  /// 获取HTTP客户端（用于图片加载）
  http.Client get httpClient => _httpClient;
}

/// 预加载小部件 - 在应用启动时显示预加载进度
class PreloadWidget extends StatefulWidget {
  final Widget child;
  
  const PreloadWidget({super.key, required this.child});
  
  @override
  State<PreloadWidget> createState() => _PreloadWidgetState();
}

class _PreloadWidgetState extends State<PreloadWidget> {
  final PreloadManager _preloadManager = PreloadManager();
  bool _showPreloadScreen = true;
  int _loadedTasks = 0;
  int _totalTasks = 12; // 4个分类 × 3页 = 12个任务
  
  @override
  void initState() {
    super.initState();
    _startPreloading();
  }
  
  Future<void> _startPreloading() async {
    await _preloadManager.startPreloading(
      onProgress: (loaded, total) {
        if (mounted) {
          setState(() {
            _loadedTasks = loaded;
            _totalTasks = total;
          });
        }
      },
      onPreloadComplete: () {
        // 页面预加载完成后，立即进入主界面
        if (mounted) {
          setState(() {
            _showPreloadScreen = false;
          });
        }
      }
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (_showPreloadScreen) {
      return _buildPreloadScreen();
    }
    
    return widget.child;
  }
  
  Widget _buildPreloadScreen() {
    final progress = _loadedTasks / _totalTasks;
    
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 加载动画
            SizedBox(
              width: 80,
              height: 80,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 6,
                    backgroundColor: Colors.blue.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
                  ),
                  Icon(
                    Icons.workspaces_outline,
                    size: 40,
                    color: Colors.blue.shade600,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 标题
            Text(
              '正在准备创意工坊数据',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // 进度文本
            Text(
              '${_loadedTasks}/$_totalTasks 页面已加载',
              style: TextStyle(
                fontSize: 14,
                color: Colors.blue.shade600,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // 进度百分比
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // 提示信息
            Text(
              '请稍候，这有助于提升后续浏览体验',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
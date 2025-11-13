// version_manager.dart
/// 版本管理器，负责检查应用更新

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
// 导入配置管理器
import 'config_manager.dart';

class VersionManager {
  static final VersionManager _instance = VersionManager._internal();
  
  // 版本号常量 - 集中管理
  static const String CURRENT_VERSION = "0.1.0";
  static const String APP_NAME = "Duckov Mod Manager";
  static const String APP_DESCRIPTION = "Escape from Duckov 模组管理器";
  
  factory VersionManager() {
    return _instance;
  }
  
  VersionManager._internal() {
    // 测试用的 GitHub 仓库
    _githubRepo = "WavesMan/Duckov_Mod_Manager";
    _githubApiUrl = "https://api.github.com/repos/$_githubRepo/releases/latest";
  }
  
  late String _githubRepo;
  late String _githubApiUrl;
  
  /// 获取当前应用版本
  String getCurrentVersion() {
    // 使用集中管理的版本常量
    return CURRENT_VERSION;
  }
  
  /// 格式化版本字符串为标准格式 (major.minor.patch)
  String formatVersion(String versionStr) {
    var formatted = versionStr;
    
    // 移除前缀
    while (formatted.startsWith('v')) {
      formatted = formatted.substring(1);
    }
    while (formatted.startsWith('V')) {
      formatted = formatted.substring(1);
    }
    
    // 移除后缀
    final dashIndex = formatted.indexOf('-');
    if (dashIndex != -1) {
      formatted = formatted.substring(0, dashIndex);
    }
    
    formatted = formatted.trim();
    
    // 移除前缀如 "EXE-v", "v" 等
    final cleaned = formatted.replaceAll(RegExp(r'^[A-Za-z\-_]*v?'), '');
    
    // 分割版本号
    final parts = cleaned.split('.');
    
    // 确保至少有 major.minor.patch 三部分
    if (parts.length == 1) {
      // 只有主版本号，添加 .0.0
      return "${parts[0]}.0.0";
    } else if (parts.length == 2) {
      // 有主版本号和次版本号，添加 .0
      return "${parts[0]}.${parts[1]}.0";
    } else {
      // 已经有三个部分，直接返回
      return parts.sublist(0, 3).join('.');
    }
  }
  
  /// 比较两个版本号
  /// 返回: 1 表示 version1 > version2, -1 表示 version1 < version2, 0 表示相等
  int compareVersions(String version1, String version2) {
    final v1Parts = version1.split('.').map(int.parse).toList();
    final v2Parts = version2.split('.').map(int.parse).toList();
    
    // 确保两个版本号都有相同数量的部分
    final maxParts = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;
    
    while (v1Parts.length < maxParts) v1Parts.add(0);
    while (v2Parts.length < maxParts) v2Parts.add(0);
    
    for (int i = 0; i < maxParts; i++) {
      if (v1Parts[i] > v2Parts[i]) {
        return 1;
      } else if (v1Parts[i] < v2Parts[i]) {
        return -1;
      }
    }
    
    return 0;
  }
  
  /// 获取最新的发布信息
  Future<Map<String, dynamic>?> getLatestReleaseInfo() async {
    try {
      print("[VersionManager] 正在检查更新，API URL: $_githubApiUrl");
      
      // 设置请求头，避免 GitHub API 限流
      final headers = {
        'Accept': 'application/vnd.github.v3+json',
        'User-Agent': 'Duckov-Mod-Manager'
      };
      
      final response = await http.get(
        Uri.parse(_githubApiUrl),
        headers: headers,
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final releaseData = json.decode(response.body);
        print("[VersionManager] 成功获取发布信息: ${releaseData['tag_name'] ?? 'Unknown'}");
        return releaseData;
      } else {
        print("[VersionManager] 获取发布信息失败，状态码: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("[VersionManager] 获取发布信息失败: $e");
      return null;
    }
  }
  
  /// 检查是否有更新可用
  Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      final latestRelease = await getLatestReleaseInfo();
      final currentVersion = getCurrentVersion();
      
      if (latestRelease == null) {
        return {
          'has_update': false,
          'error': '无法获取发布信息',
        };
      }
      
      final latestVersion = latestRelease['tag_name'] ?? '0.0.0';
      final downloadUrl = latestRelease['html_url'] ?? '';
      final releaseNotes = latestRelease['body'] ?? '';
      
      final hasUpdate = compareVersions(currentVersion, latestVersion) < 0;
      
      return {
        'has_update': hasUpdate,
        'current_version': currentVersion,
        'latest_version': latestVersion,
        'download_url': downloadUrl,
        'release_notes': releaseNotes,
      };
    } catch (e) {
      // 检查更新失败: $e
      return {
        'has_update': false,
        'error': e.toString(),
      };
    }
  }
  
  /// 打开浏览器跳转到下载页面
  Future<bool> openDownloadPage(String downloadUrl) async {
    try {
      final uri = Uri.parse(downloadUrl);
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        // 成功打开下载页面: $downloadUrl
        return true;
      } else {
        // 无法打开下载页面: $downloadUrl
        return false;
      }
    } catch (e) {
      // 打开下载页面失败: $e
      return false;
    }
  }
}


// 创建全局版本管理器实例
final versionManager = VersionManager();
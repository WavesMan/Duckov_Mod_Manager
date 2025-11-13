// steam_workshop_service.dart
/// Steam创意工坊服务类 - 对应Python版本的SteamWorkshopService

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart';

class SteamWorkshopService {
  /// Steam创意工坊服务类，支持按不同方式排序获取物品信息
  
  static const String baseUrl = "https://steamcommunity.com/workshop/browse/";
  static const Map<String, String> headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36'
  };
  
  /// 排序参数映射
  static const Map<String, String> sortParams = {
    'most_popular': 'totaluniquesubscribers',  // 最多订阅
    'top_rated': 'rating',                     // 最高评分
    'newest': 'mostrecent',                    // 最新
    'last_updated': 'lastupdated'              // 最近更新
  };

  /// 获取Steam创意工坊物品信息
  /// 
  /// [appId] 游戏ID (例如: "3167020" for Duckov Game)
  /// [sortBy] 排序方式 ('most_popular', 'top_rated', 'newest', 'last_updated')
  /// [searchTerm] 搜索关键词
  /// [page] 页码
  /// 
  /// 返回包含物品信息列表和分页信息的字典
  Future<Map<String, dynamic>?> getWorkshopItems(
    String appId, 
    String sortBy, 
    String searchTerm, 
    int page
  ) async {
    if (!sortParams.containsKey(sortBy)) {
      throw ArgumentError("不支持的排序方式: $sortBy. 支持的方式: ${sortParams.keys.toList()}");
    }

    // 构建URL参数
    final params = {
      'appid': appId,
      'section': 'readytouseitems',
      'actualsort': sortParams[sortBy],
      'p': page.toString(),
      'browsesort': sortParams[sortBy]
    };
    
    if (searchTerm.isNotEmpty) {
      params['searchtext'] = searchTerm;
    }

    // 构建完整的URL
    final url = baseUrl + '?' + params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value ?? '')}').join('&');

    try {
      final response = await http.get(Uri.parse(url), headers: headers).timeout(const Duration(seconds: 15));
      
      if (response.statusCode != 200) {
        print("[SteamWorkshopService] 获取页面时出错: ${response.statusCode}");
        return null;
      }

      final document = html_parser.parse(response.body);
      final items = <Map<String, dynamic>>[];

      // 查找物品容器
      final itemElements = document.querySelectorAll('div.workshopItem');
      
      for (final itemElement in itemElements) {
        try {
          final itemInfo = _extractItemInfo(itemElement);
          if (itemInfo != null) {
            items.add(itemInfo);
          }
        } catch (e) {
          print("[SteamWorkshopService] 解析物品时出错: $e");
          continue;
        }
      }

      // 获取分页信息
      final totalPages = _extractPaginationInfo(document);
      
      return {
        'items': items,
        'current_page': page,
        'total_pages': totalPages
      };
    } catch (e) {
      print("[SteamWorkshopService] 获取创意工坊数据时出错: $e");
      return null;
    }
  }

  /// 从HTML元素中提取单个物品信息
  Map<String, dynamic>? _extractItemInfo(Element itemElement) {
    try {
      // 提取物品ID和URL
      final linkElement = itemElement.querySelector('a.ugc');
      if (linkElement == null) return null;

      final url = linkElement.attributes['href'] ?? '';
      final itemId = linkElement.attributes['data-publishedfileid'] ?? '';
      
      // 提取物品名称
      final titleElement = itemElement.querySelector('div.workshopItemTitle');
      final name = titleElement?.text?.trim() ?? '未知名称';

      // 提取预览图像
      final imageElement = itemElement.querySelector('img.workshopItemPreviewImage');
      final previewUrl = imageElement?.attributes['src'] ?? '';

      // 提取作者信息
      final authorElement = itemElement.querySelector('div.workshopItemAuthorName');
      String author = '';
      String authorLink = '';
      
      if (authorElement != null) {
        final authorLinkElement = authorElement.querySelector('a');
        if (authorLinkElement != null) {
          author = authorLinkElement.text?.trim() ?? '';
          authorLink = authorLinkElement.attributes['href'] ?? '';
        }
      }

      // 提取描述信息
      final descriptionElement = itemElement.querySelector('div.workshopItemDescription');
      final description = descriptionElement?.text?.trim() ?? '暂无描述';

      // 简化处理评分信息（实际实现可能需要更复杂的解析）
      final rating = 0.0;
      final ratingCount = 0;
      final subscriptions = 0;
      final favorites = 0;

      final itemInfo = {
        'id': itemId,
        'name': name,
        'title': name,  // 添加title字段以匹配页面使用
        'url': url,
        'preview_url': previewUrl,
        'author': author,
        'author_link': authorLink,
        'rating': rating,
        'rating_count': ratingCount,
        'subscriptions': subscriptions,
        'favorites': favorites,
        'description': description
      };

      return itemInfo;
    } catch (e) {
      print("[SteamWorkshopService] 提取物品信息时出错: $e");
      return null;
    }
  }

  /// 从HTML中提取分页信息
  int _extractPaginationInfo(Document document) {
    try {
      final paginationControls = document.querySelector('div.workshopBrowsePagingControls');
      if (paginationControls == null) return 1;
      
      // 查找所有页码链接
      final pageLinks = paginationControls.querySelectorAll('a.pagelink');
      if (pageLinks.isEmpty) return 1;
      
      // 提取最大的页码数
      int maxPage = 1;
      for (final link in pageLinks) {
        final href = link.attributes['href'] ?? '';
        final pageMatch = RegExp(r'&p=(\d+)').firstMatch(href);
        if (pageMatch != null) {
          final pageNum = int.tryParse(pageMatch.group(1) ?? '1');
          if (pageNum != null && pageNum > maxPage) {
            maxPage = pageNum;
          }
        }
      }
      
      return maxPage;
    } catch (e) {
      print("[SteamWorkshopService] 提取分页信息时出错: $e");
      return 1;
    }
  }
}
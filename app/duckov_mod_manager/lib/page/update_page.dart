// update_page.dart
/// 更新弹窗页面

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/version_manager.dart';
import '../services/theme_manager.dart';

class UpdateDialog extends StatefulWidget {
  final Map<String, dynamic> updateInfo;

  const UpdateDialog({Key? key, required this.updateInfo}) : super(key: key);

  @override
  State<UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<UpdateDialog> {
  @override
  Widget build(BuildContext context) {
    final hasUpdate = widget.updateInfo['has_update'] as bool;
    final currentVersion = widget.updateInfo['current_version'] as String? ?? versionManager.getCurrentVersion();
    final latestVersion = widget.updateInfo['latest_version'] as String? ?? 'Unknown';
    final releaseNotes = widget.updateInfo['release_notes'] as String? ?? '暂无更新说明';
    final downloadUrl = widget.updateInfo['download_url'] as String? ?? '';

    return AlertDialog(
      backgroundColor: ThemeManager.getThemeColor('surface'),
      title: Row(
        children: [
          Icon(Icons.system_update, color: ThemeManager.getThemeColor('primary')),
          const SizedBox(width: 10),
          Text(hasUpdate ? '发现新版本' : '版本信息', style: ThemeManager.headingTextStyle(level: 4)),
        ],
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.6,
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(), // 添加物理效果
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 版本信息
              _buildVersionInfo(currentVersion, latestVersion, hasUpdate),
              const SizedBox(height: 16),
              // 更新说明标题
              Text(
                '更新说明',
                style: ThemeManager.headingTextStyle(level: 4),
              ),
              const SizedBox(height: 8),
              
              // 更新说明内容 (Markdown格式，支持选择和复制)
              // 更新说明内容 (Markdown格式，支持选择和复制)
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: ThemeManager.getThemeColor('background'),
                  border: Border.all(
                    color: ThemeManager
                        .getThemeColor('text_secondary')
                        .withOpacity(0.3),
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Scrollbar(
                  child: Markdown(
                    data: releaseNotes,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(
                      Theme.of(context).copyWith(
                        // 整体背景/画布颜色，避免暗色下出现白底
                        scaffoldBackgroundColor:
                        ThemeManager.getThemeColor('background'),
                        canvasColor:
                        ThemeManager.getThemeColor('background'),
                        textTheme: Theme.of(context).textTheme.apply(
                          bodyColor: ThemeManager
                              .getThemeColor('text_primary'),
                          displayColor: ThemeManager
                              .getThemeColor('text_primary'),
                        ),
                      ),
                    ).copyWith(
                      // 如需可单独覆盖代码块、链接等
                      a: ThemeManager.bodyTextStyle(
                        size: 14,
                        color: ThemeManager.getThemeColor('primary'),
                      ),
                      p: ThemeManager.bodyTextStyle(size: 14),
                      code: ThemeManager.bodyTextStyle(
                        size: 13,
                        color: ThemeManager.getThemeColor('on_background'),
                      ).copyWith(
                        backgroundColor: ThemeManager
                            .getThemeColor('surface')
                            .withOpacity(0.6),
                        fontFamily: 'monospace',
                      ),
                    ),
                    onTapLink: (text, href, title) {
                      if (href != null) _launchURL(href);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop('later');
          },
          child: const Text('稍后提醒'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop('workshop');
          },
          child: const Text('前往本创意工坊'),
        ),
        if (hasUpdate)
          ElevatedButton(
            onPressed: () {
              if (downloadUrl.isNotEmpty) {
                _launchURL(downloadUrl);
              }
              Navigator.of(context).pop('update');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ThemeManager.getThemeColor('primary'),
              foregroundColor: ThemeManager.getThemeColor('on_primary'),
            ),
            child: const Text('前往更新'),
          ),
      ],
    );
  }

  Widget _buildVersionInfo(String currentVersion, String latestVersion, bool hasUpdate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '当前版本: v$currentVersion',
          style: ThemeManager.bodyTextStyle(size: 14),
        ),
        const SizedBox(height: 4),
        Text(
          '最新版本: v$latestVersion',
          style: TextStyle(
            fontSize: 14,
            color: hasUpdate 
                ? ThemeManager.getThemeColor('error') 
                : ThemeManager.getThemeColor('success'),
            fontWeight: hasUpdate ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        if (hasUpdate) ...[
          const SizedBox(height: 8),
          Text(
            '发现新版本，请及时更新以获得最新功能和修复',
            style: TextStyle(
              fontSize: 12,
              color: ThemeManager.getThemeColor('error'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            '您当前使用的是最新版本',
            style: TextStyle(
              fontSize: 12,
              color: ThemeManager.getThemeColor('success'),
            ),
          ),
        ]
      ],
    );
  }

  void _launchURL(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    } catch (e) {
      // 忽略打开URL时的错误
      debugPrint('无法打开URL: $url, 错误: $e');
    }
  }
}

/// 显示更新弹窗的便捷函数
Future<String?> showUpdateDialog(BuildContext context, Map<String, dynamic> updateInfo) async {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return UpdateDialog(updateInfo: updateInfo);
    },
  );
}
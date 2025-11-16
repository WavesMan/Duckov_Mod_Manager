import 'dart:io';
import 'package:flutter/material.dart';
import '../../services/mod_manager.dart';
import '../../services/theme_manager.dart';

class ModCard extends StatelessWidget {
  final LocalModInfo mod;
  final bool isSelected;
  final Future<bool> Function(String) getEnabledStatus;
  final void Function(String, bool) onToggleSelect;
  final void Function(String) onToggleStatus;
  final void Function(LocalModInfo) onShowDetails;

  const ModCard({
    Key? key,
    required this.mod,
    required this.isSelected,
    required this.getEnabledStatus,
    required this.onToggleSelect,
    required this.onToggleStatus,
    required this.onShowDetails,
  }) : super(key: key);

  Widget _preview(LocalModInfo mod) {
    if (mod.previewImagePath != null) {
      return Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: ThemeManager.getThemeColor('outline'),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(
            File(mod.previewImagePath!),
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _defaultPreview();
            },
          ),
        ),
      );
    }
    return _defaultPreview();
  }

  Widget _defaultPreview() {
    return Container(
      height: 140,
      width: double.infinity,
      decoration: BoxDecoration(
        color: ThemeManager.getThemeColor('background'),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ThemeManager.getThemeColor('outline'),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 32,
            color: ThemeManager.getThemeColor('text_secondary'),
          ),
          const SizedBox(height: 8),
          Text(
            '无预览图',
            style: ThemeManager.bodyTextStyle().copyWith(
              fontSize: 12,
              color: ThemeManager.getThemeColor('text_secondary'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _description(String description) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: Scrollbar(
            child: Text(
              description.isEmpty ? '暂无描述' : description,
              style: ThemeManager.bodyTextStyle().copyWith(
                fontSize: 11,
                color: ThemeManager.getThemeColor('text_secondary'),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _stats(LocalModInfo mod, bool isEnabled) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isEnabled
                ? ThemeManager.getThemeColor('onSuccess').withOpacity(0.1)
                : ThemeManager.getThemeColor('surface'),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            isEnabled ? '已启用' : '已禁用',
            style: TextStyle(
              color: isEnabled
                  ? ThemeManager.getThemeColor('success')
                  : ThemeManager.getThemeColor('error'),
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: getEnabledStatus(mod.id),
      builder: (context, snapshot) {
        final isEnabled = snapshot.data ?? false;
        return Card(
          elevation: 3,
          color: isSelected
              ? ThemeManager.getThemeColor('primary').withOpacity(0.1)
              : ThemeManager.getThemeColor('background'),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: InkWell(
            onTap: () => onToggleSelect(mod.id, !isSelected),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _preview(mod),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Checkbox(
                              value: isSelected,
                              onChanged: (value) => onToggleSelect(mod.id, value ?? false),
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
                        _stats(mod, isEnabled),
                        const SizedBox(height: 6),
                        Expanded(
                          child: SizedBox(
                            height: 80,
                            child: _description(mod.description),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 80,
                    padding: const EdgeInsets.only(left: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () => onToggleStatus(mod.id),
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
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => onShowDetails(mod),
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
}
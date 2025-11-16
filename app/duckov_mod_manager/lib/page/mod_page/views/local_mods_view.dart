import 'package:flutter/material.dart';
import '../../../services/theme_manager.dart';
import '../../../services/mod_manager.dart';
import '../../mod_page/mod_card.dart';
import '../../mod_page/sort_controls.dart';

class LocalModsView extends StatelessWidget {
  final bool isLoading;
  final List<LocalModInfo> filteredMods;
  final List<LocalModInfo> localMods;
  final ScrollController scrollController;
  final String sortBy;
  final bool sortReverse;
  final ValueChanged<String> onChangeSortBy;
  final VoidCallback onToggleReverse;
  final Set<String> selectedModIds;
  final Future<bool> Function(String) getEnabledStatus;
  final void Function(String, bool) onToggleSelect;
  final void Function(String) onToggleStatus;
  final void Function(LocalModInfo) onShowDetails;

  const LocalModsView({
    Key? key,
    required this.isLoading,
    required this.filteredMods,
    required this.localMods,
    required this.scrollController,
    required this.sortBy,
    required this.sortReverse,
    required this.onChangeSortBy,
    required this.onToggleReverse,
    required this.selectedModIds,
    required this.getEnabledStatus,
    required this.onToggleSelect,
    required this.onToggleStatus,
    required this.onShowDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.folder, color: Colors.blue, size: 16),
                const SizedBox(width: 4),
                Text('本地模组 (${localMods.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const Spacer(),
                SortControls(
                  sortBy: sortBy,
                  onChangeSortBy: onChangeSortBy,
                  sortReverse: sortReverse,
                  onToggleReverse: onToggleReverse,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '路径: ${localMods.isNotEmpty ? localMods.first.path : '未找到路径'}',
              style: ThemeManager.bodyTextStyle().copyWith(fontSize: 9, color: Colors.grey[600]),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.folder_off, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('暂无本地模组', style: ThemeManager.headingTextStyle(level: 4)),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        controller: scrollController,
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
                                if (index >= filteredMods.length || filteredMods.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                final mod = filteredMods[index];
                                return ModCard(
                                  mod: mod,
                                  isSelected: selectedModIds.contains(mod.id),
                                  getEnabledStatus: getEnabledStatus,
                                  onToggleSelect: onToggleSelect,
                                  onToggleStatus: onToggleStatus,
                                  onShowDetails: onShowDetails,
                                );
                              },
                              childCount: filteredMods.length,
                            ),
                          ),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}
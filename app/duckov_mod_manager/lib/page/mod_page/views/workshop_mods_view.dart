import 'package:flutter/material.dart';
import '../../../services/theme_manager.dart';
import '../../mod_page/mod_card.dart';
import '../../mod_page/batch_controls.dart';
import '../../mod_page/pagination_controls.dart';
import '../../../services/mod_manager.dart';

class WorkshopModsView extends StatelessWidget {
  final bool isLoading;
  final List<LocalModInfo> filteredMods;
  final ScrollController scrollController;
  final bool selectAll;
  final ValueChanged<bool?> onToggleSelectAll;
  final Set<String> selectedModIds;
  final Future<bool> Function(String) getEnabledStatus;
  final void Function(String, bool) onToggleSelect;
  final void Function(String) onToggleStatus;
  final void Function(LocalModInfo) onShowDetails;
  final VoidCallback onEnableSelected;
  final VoidCallback onDisableSelected;
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevPage;
  final VoidCallback? onNextPage;

  const WorkshopModsView({
    Key? key,
    required this.isLoading,
    required this.filteredMods,
    required this.scrollController,
    required this.selectAll,
    required this.onToggleSelectAll,
    required this.selectedModIds,
    required this.getEnabledStatus,
    required this.onToggleSelect,
    required this.onToggleStatus,
    required this.onShowDetails,
    required this.onEnableSelected,
    required this.onDisableSelected,
    required this.currentPage,
    required this.totalPages,
    this.onPrevPage,
    this.onNextPage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Checkbox(
                  value: selectAll,
                  onChanged: onToggleSelectAll,
                  activeColor: ThemeManager.getThemeColor('primary'),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                Text('全选', style: TextStyle(fontSize: 12, color: ThemeManager.getThemeColor('text_primary'))),
                const Spacer(),
              ],
            ),
          ),
          BatchControls(
            visible: selectedModIds.isNotEmpty,
            selectedCount: selectedModIds.length,
            onEnableSelected: onEnableSelected,
            onDisableSelected: onDisableSelected,
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredMods.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.inbox, size: 48, color: Colors.grey),
                            const SizedBox(height: 12),
                            Text('暂无创意工坊模组', style: ThemeManager.headingTextStyle(level: 4)),
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
                          SliverToBoxAdapter(
                            child: PaginationControls(
                              currentPage: currentPage,
                              totalPages: totalPages,
                              onPrev: onPrevPage,
                              onNext: onNextPage,
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
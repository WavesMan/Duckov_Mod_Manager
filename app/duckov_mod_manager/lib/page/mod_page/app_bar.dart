import 'package:flutter/material.dart';
import '../../services/theme_manager.dart';
import 'bridge_status_indicator.dart';

class ModPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;
  final void Function(int) onTabChanged;
  final bool isBridgeConnected;
  final bool isCheckingBridgeConnection;
  final VoidCallback onReconnectBridge;
  final VoidCallback? onManualSync;
  final bool isSyncInProgress;
  final VoidCallback onRefresh;

  const ModPageAppBar({
    Key? key,
    required this.tabController,
    required this.onTabChanged,
    required this.isBridgeConnected,
    required this.isCheckingBridgeConnection,
    required this.onReconnectBridge,
    required this.onManualSync,
    required this.isSyncInProgress,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      title: Text('模组管理', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
      bottom: TabBar(
        controller: tabController,
        onTap: onTabChanged,
        tabs: const [
          Tab(icon: Icon(Icons.store), child: Text('创意工坊')),
          Tab(icon: Icon(Icons.folder), child: Text('本地模组')),
        ],
      ),
      actions: [
        BridgeStatusIndicator(
          isConnected: isBridgeConnected,
          isChecking: isCheckingBridgeConnection,
          onReconnect: onReconnectBridge,
        ),
        IconButton(
          icon: Stack(children: [
            Icon(Icons.sync, color: isBridgeConnected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurfaceVariant),
            if (isSyncInProgress)
              const Positioned.fill(child: CircularProgressIndicator(strokeWidth: 2)),
          ]),
          onPressed: isBridgeConnected ? onManualSync : null,
          tooltip: isSyncInProgress ? '同步进行中...' : '手动同步到游戏',
        ),
        IconButton(icon: const Icon(Icons.refresh), onPressed: onRefresh),
      ],
    );
  }
}
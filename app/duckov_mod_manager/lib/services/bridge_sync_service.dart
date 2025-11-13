import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mod_manager_bridge_client.dart';
import 'mod_manager.dart';

/// Bridge同步服务 - 负责离线文件编辑模式下的Mod状态同步
class BridgeSyncService {
  final ModManagerBridgeClient _bridgeClient;
  final ModManager _modManager;
  
  // 连接状态监听
  bool _isConnected = false;
  StreamSubscription<bool>? _connectionSubscription;
  
  // 同步状态
  bool _isSyncing = false;
  
  // 同步进度回调
  Function(SyncStatus status, double progress, String message)? _progressCallback;

  BridgeSyncService(this._bridgeClient, this._modManager) {
    print('[BridgeSyncService] 初始化Bridge同步服务');
    
    // 监听连接状态变化
    _connectionSubscription = _bridgeClient.isConnectedStream.listen((status) {
      _onConnectionStatusChanged(status);
    });
    
    print('[BridgeSyncService] Bridge同步服务初始化完成');
  }

  /// 设置进度回调函数（用于UI更新）
  void setProgressCallback(Function(SyncStatus status, double progress, String message) callback) {
    _progressCallback = callback;
  }

  /// 处理连接状态变化
  void _onConnectionStatusChanged(bool isConnected) {
    final previousStatus = _isConnected;
    _isConnected = isConnected;
    
    print('[BridgeSyncService] 连接状态变化: $previousStatus -> $isConnected');
    
    // 只在断开 -> 连接时自动触发同步
    if (isConnected && !_isSyncing) {
      print('[BridgeSyncService] 检测到Bridge重新连接，自动触发同步');
      // 使用Timer延迟一点再同步，确保连接稳定
      Timer(Duration(seconds: 1), () {
        _syncLocalStateToBridge();
      });
    }
  }

  /// 启动同步服务
  void start() {
    print('[BridgeSyncService] 启动Bridge连接监听');
    
    // 监听Bridge连接状态变化，只在断开->连接时触发同步
    _connectionSubscription = _bridgeClient.connectionStatusStream.listen(
      (isConnected) async {
        print('[BridgeSyncService] Bridge连接状态变化: ${isConnected ? "已连接" : "已断开"}');
        
        if (isConnected && !_isSyncing) {
          await _syncLocalStateToBridge();
        }
      }
    );
  }

  /// 手动触发同步（用于UI手动同步按钮）
  Future<void> forceSync() async {
    print('[BridgeSyncService] 手动触发同步');
    await _syncLocalStateToBridge();
  }

  /// 核心同步逻辑：将本地Mod状态同步到Bridge
  Future<void> _syncLocalStateToBridge() async {
    if (_isSyncing) {
      print('[BridgeSyncService] 同步正在进行中，跳过重复执行');
      return;
    }

    _isSyncing = true;
    _progressCallback?.call(const SyncStatusStarted(), 0.0, '开始同步Mod状态...');
    
    print('[BridgeSyncService] ===== 开始同步本地Mod状态到Bridge =====');
    final stopwatch = Stopwatch()..start();
    
    try {
      // 首先检查Bridge是否在线
      print('[BridgeSyncService] 步骤0: 检查Bridge连接状态');
      _progressCallback?.call(const SyncStatusCheckingConnection(), 0.1, '检查Bridge连接状态...');
      
      final isBridgeOnline = await _bridgeClient.isBridgeOnline();
      if (!isBridgeOnline) {
        print('[BridgeSyncService] Bridge服务不在线，无法进行同步');
        _progressCallback?.call(SyncStatusError('Bridge服务不在线，无法同步'), 1.0, 'Bridge服务不在线，无法同步');
        return;
      }
      // 步骤1: 获取本地Mod状态
      print('[BridgeSyncService] 步骤1: 获取本地Mod状态');
      _progressCallback?.call(const SyncStatusReadingLocal(), 0.2, '读取本地Mod状态...');
      
      final localMods = await _modManager.getLocalMods();
      final localState = <String, bool>{};
      
      for (final mod in localMods) {
        final modId = mod.id ?? mod.name;
        if (modId.isNotEmpty) {
          localState[modId] = mod.enabled ?? false;
        }
      }
      
      if (localState.isEmpty) {
        print('[BridgeSyncService] 未找到本地Mod状态，无需同步');
        _progressCallback?.call(const SyncStatusCompleted(0, 0, 0), 1.0, '同步完成 - 无需变更');
        return;
      }
      
      final localEnabledCount = localState.values.where((enabled) => enabled).length;
      print('[BridgeSyncService] 本地状态: $localEnabledCount/${localState.length} 个Mod已启用');
      
      // 步骤2: 获取Bridge远端状态
      print('[BridgeSyncService] 步骤2: 获取Bridge远端状态');
      _progressCallback?.call(const SyncStatusReadingRemote(), 0.4, '读取Bridge远端状态...');
      
      final remoteMods = await _bridgeClient.getModList();
      final remoteState = <String, bool>{};
      
      for (final mod in remoteMods) {
        final modId = mod.id ?? mod.name;
        if (modId.isNotEmpty) {
          remoteState[modId] = mod.enabled ?? false;
        }
      }
      
      final remoteEnabledCount = remoteState.values.where((enabled) => enabled).length;
      print('[BridgeSyncService] Bridge状态: $remoteEnabledCount/${remoteState.length} 个Mod已启用');
      
      // 步骤3: 计算差异
      print('[BridgeSyncService] 步骤3: 计算状态差异');
      _progressCallback?.call(const SyncStatusCalculating(), 0.6, '计算状态差异...');
      
      final toEnable = <String>[];
      final toDisable = <String>[];
      
      localState.forEach((modId, shouldEnable) {
        final current = remoteState[modId] ?? false;
        
        if (shouldEnable && !current) {
          toEnable.add(modId);
        } else if (!shouldEnable && current) {
          toDisable.add(modId);
        }
      });
      
      print('[BridgeSyncService] 差异计算结果: 需启用=${toEnable.length}, 需禁用=${toDisable.length}');
      
      // 步骤4: 批量执行同步操作
      final syncResults = <String, bool>{};
      
      if (toEnable.isNotEmpty) {
        print('[BridgeSyncService] 步骤4a: 批量启用 ${toEnable.length} 个Mod');
        _progressCallback?.call(SyncStatusEnabling(toEnable.length), 0.8, '正在启用 ${toEnable.length} 个Mod...');
        
        for (final modId in toEnable) {
          try {
            final result = await _bridgeClient.enableMod(modId);
            syncResults[modId] = result;
          } catch (e) {
            print('[BridgeSyncService] 启用Mod失败: $modId - $e');
            syncResults[modId] = false;
          }
        }
      }
      
      if (toDisable.isNotEmpty) {
        print('[BridgeSyncService] 步骤4b: 批量禁用 ${toDisable.length} 个Mod');
        _progressCallback?.call(SyncStatusDisabling(toDisable.length), 0.9, '正在禁用 ${toDisable.length} 个Mod...');
        
        for (final modId in toDisable) {
          try {
            final result = await _bridgeClient.disableMod(modId);
            syncResults[modId] = result;
          } catch (e) {
            print('[BridgeSyncService] 禁用Mod失败: $modId - $e');
            syncResults[modId] = false;
          }
        }
      }
      
      // 步骤5: 统计同步结果
      final successfulSyncs = syncResults.values.where((result) => result).length;
      final failedSyncs = syncResults.length - successfulSyncs;
      
      stopwatch.stop();
      
      if (successfulSyncs > 0 || failedSyncs > 0) {
        print('[BridgeSyncService] 同步完成 - 成功: $successfulSyncs, 失败: $failedSyncs (耗时: ${stopwatch.elapsedMilliseconds}ms)');
        _progressCallback?.call(SyncStatusCompleted(successfulSyncs, failedSyncs, stopwatch.elapsedMilliseconds), 1.0, '同步完成 - 成功: $successfulSyncs, 失败: $failedSyncs');
      } else {
        print('[BridgeSyncService] 同步完成 - 状态已一致，无需变更 (耗时: ${stopwatch.elapsedMilliseconds}ms)');
        _progressCallback?.call(SyncStatusCompleted(successfulSyncs, failedSyncs, stopwatch.elapsedMilliseconds), 1.0, '同步完成 - 状态已一致');
      }
      
    } catch (e, stackTrace) {
      print('[BridgeSyncService] 同步失败: $e');
      print('[BridgeSyncService] 错误堆栈: $stackTrace');
      
      _progressCallback?.call(SyncStatusError(e.toString()), 1.0, '同步失败: $e');
      
    } finally {
      _isSyncing = false;
      print('[BridgeSyncService] ===== 同步流程结束 =====');
    }
  }

  /// 释放资源
  void dispose() {
    print('[BridgeSyncService] 释放Bridge同步服务资源');
    
    _connectionSubscription?.cancel();
    _progressCallback = null;
  }
}

/// 同步状态枚举
sealed class SyncStatus {
  const SyncStatus();
}

/// 同步进行中状态
class SyncStatusInProgress extends SyncStatus {
  const SyncStatusInProgress();
}

/// 同步开始
class SyncStatusStarted extends SyncStatusInProgress {
  const SyncStatusStarted();
}

/// 检查连接状态
class SyncStatusCheckingConnection extends SyncStatusInProgress {
  const SyncStatusCheckingConnection();
}

/// 读取本地状态
class SyncStatusReadingLocal extends SyncStatusInProgress {
  const SyncStatusReadingLocal();
}

/// 读取远端状态
class SyncStatusReadingRemote extends SyncStatusInProgress {
  const SyncStatusReadingRemote();
}

/// 计算差异
class SyncStatusCalculating extends SyncStatusInProgress {
  const SyncStatusCalculating();
}

/// 启用Mod
class SyncStatusEnabling extends SyncStatusInProgress {
  final int count;
  const SyncStatusEnabling(this.count);
}

/// 禁用Mod
class SyncStatusDisabling extends SyncStatusInProgress {
  final int count;
  const SyncStatusDisabling(this.count);
}

/// 同步完成
class SyncStatusCompleted extends SyncStatus {
  final int success;
  final int failed;
  final int durationMs;
  const SyncStatusCompleted(this.success, this.failed, this.durationMs);
}

/// 同步错误
class SyncStatusError extends SyncStatus {
  final String message;
  const SyncStatusError(this.message);
}

/// 同步状态扩展方法
extension SyncStatusExtension on SyncStatus {
  String get message {
    if (this is SyncStatusStarted) {
      return '开始同步Mod状态...';
    } else if (this is SyncStatusCheckingConnection) {
      return '检查Bridge连接状态...';
    } else if (this is SyncStatusReadingLocal) {
      return '读取本地Mod状态...';
    } else if (this is SyncStatusReadingRemote) {
      return '读取Bridge远端状态...';
    } else if (this is SyncStatusCalculating) {
      return '计算状态差异...';
    } else if (this is SyncStatusEnabling) {
      final enabling = this as SyncStatusEnabling;
      return '正在启用 ${enabling.count} 个Mod...';
    } else if (this is SyncStatusDisabling) {
      final disabling = this as SyncStatusDisabling;
      return '正在禁用 ${disabling.count} 个Mod...';
    } else if (this is SyncStatusCompleted) {
      final completed = this as SyncStatusCompleted;
      return '同步完成 - 成功: ${completed.success}, 失败: ${completed.failed} (耗时: ${completed.durationMs}ms)';
    } else if (this is SyncStatusError) {
      final error = this as SyncStatusError;
      return '同步失败: ${error.message}';
    }
    return '未知状态';
  }
}
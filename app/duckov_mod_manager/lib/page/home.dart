// home.dart
/// 主页组件 - 基于Flet项目重构

import 'package:flutter/material.dart';
import 'dart:async';
import '../services/theme_manager.dart';
import '../services/process_manager.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _statusText = "";
  bool _isGameRunning = false;
  Timer? _periodicTimer;

  @override
  void initState() {
    super.initState();
    _updateGameStatus();
    // 启动定期更新任务，每2秒检查一次游戏状态
    _periodicTimer = Timer.periodic(Duration(seconds: 2), (timer) {
      _updateGameStatus();
    });
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }

  /// 更新游戏状态
  Future<void> _updateGameStatus() async {
    final isRunning = await ProcessManager.checkGameStatus();
    if (mounted) {
      setState(() {
        _isGameRunning = isRunning;
      });
    }
  }

  /// 显示状态信息
  void _showStatus(String message) {
    if (mounted) {
      setState(() {
        _statusText = message;
      });
    }
  }

  /// 清除状态信息
  void _clearStatus() {
    if (mounted) {
      setState(() {
        _statusText = "";
      });
    }
  }

  /// 处理启动/停止游戏按钮事件
  Future<void> _onLaunchClick() async {
    if (_isGameRunning) {
      // 游戏正在运行，需要停止游戏
      _showStatus("正在停止游戏...");
      try {
        final terminated = await ProcessManager.terminateProcess(ProcessManager.GAME_PROCESS_NAME);
        if (terminated) {
          _showStatus("游戏已停止");
        } else {
          _showStatus("停止游戏失败");
        }
        // 1秒后清除状态
        await Future.delayed(Duration(seconds: 1));
        _clearStatus();
      } catch (e) {
        _showStatus("停止游戏时发生错误: ${e.toString()}");
      }
    } else {
      // 游戏未运行，需要启动游戏
      _showStatus("正在启动游戏...");
      try {
        final result = await ProcessManager.launchSteamGame();
        if (result['success'] == true) {
          _showStatus("游戏启动指令已发送");
        } else {
          _showStatus("启动游戏失败: ${result['message']}");
        }
        // 1秒后清除状态
        await Future.delayed(Duration(seconds: 1));
        _clearStatus();
      } catch (e) {
        _showStatus("启动游戏时发生错误: ${e.toString()}");
      }
    }
    
    // 更新游戏状态
    await _updateGameStatus();
  }

  /// 处理重启游戏按钮事件
  Future<void> _onRestartClick() async {
    _showStatus("正在重启游戏...");
    try {
      final result = await ProcessManager.restartSteamGame();
      if (result['success'] == true) {
        _showStatus("游戏重启指令已发送");
      } else {
        _showStatus("重启游戏失败: ${result['message']}");
      }
      // 1秒后清除状态
      await Future.delayed(Duration(seconds: 1));
      _clearStatus();
    } catch (e) {
      _showStatus("重启游戏时发生错误: ${e.toString()}");
    }
    
    // 更新游戏状态
    await _updateGameStatus();
  }

  /// 创建启动/停止游戏按钮
  Widget _buildLaunchButton() {
    final colors = ThemeManager.getThemeColors();
    final buttonText = _isGameRunning ? "停止游戏" : "启动游戏";
    final buttonIcon = _isGameRunning ? Icons.stop : Icons.play_arrow;
    final buttonColor = _isGameRunning ? colors['error'] : colors['primary'];
    
    return ElevatedButton(
      onPressed: _onLaunchClick,
      style: ElevatedButton.styleFrom(
        backgroundColor: buttonColor,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(buttonIcon, color: colors['on_primary']),
          SizedBox(width: 5),
          Text(
            buttonText,
            style: TextStyle(
              color: colors['on_primary'],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 创建重启游戏按钮
  Widget _buildRestartButton() {
    final colors = ThemeManager.getThemeColors();
    
    return ElevatedButton(
      onPressed: _onRestartClick,
      style: ElevatedButton.styleFrom(
        backgroundColor: colors['secondary'],
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restart_alt, color: colors['on_secondary']),
          SizedBox(width: 5),
          Text(
            "重启游戏",
            style: TextStyle(
              color: colors['on_secondary'],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  /// 创建状态文本显示区域
  Widget _buildStatusText() {
    final colors = ThemeManager.getThemeColors();
    
    return Text(
      _statusText,
      style: TextStyle(
        fontSize: 14,
        color: colors['text_secondary'],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            headingText('欢迎使用Duckov Mod Manager', level: 1),
            SizedBox(height: 10),
            bodyText('这是一个逃离鸭科夫的模组管理工具，可以帮助您轻松管理游戏模组。'),
            
            Divider(height: 20),

            headingText('游戏控制', level: 2),
            SizedBox(height: 5),
            bodyText('快速启动或重启您的游戏'),
            SizedBox(height: 15),

            Row(
              children: [
                _buildLaunchButton(),
                SizedBox(width: 10),
                _buildRestartButton(),
              ],
            ),
            
            SizedBox(height: 10),
            _buildStatusText(),

            Divider(height: 20),
            
            headingText('开始使用', level: 2),
            SizedBox(height: 5),
            bodyText('点击左侧导航栏中的选项来开始使用不同的功能。'),
            
            Divider(height: 20),
            
            Text(
              '版本 0.1.0',
              style: TextStyle(
                fontSize: 12,
                color: ThemeManager.getThemeColors()['text_secondary'],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 便捷函数 - 创建主页视图
Widget homePageView() {
  return HomePage();
}
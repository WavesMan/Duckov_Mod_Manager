// process_manager.dart
/// 进程管理服务

import 'package:process_run/process_run.dart';
import 'package:url_launcher/url_launcher.dart';

class ProcessManager {
  /// 游戏Steam ID
  static const String GAME_STEAM_ID = "3167020";
  
  /// 游戏进程名称
  static const String GAME_PROCESS_NAME = "Duckov.exe";
  
  /// 启动Steam游戏
  static Future<Map<String, dynamic>> launchSteamGame() async {
    try {
      final url = 'steam://run/$GAME_STEAM_ID';
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
        return {'success': true, 'message': '游戏启动成功'};
      } else {
        return {'success': false, 'message': '无法启动Steam URL'};
      }
    } catch (e) {
      return {'success': false, 'message': '启动失败: ${e.toString()}'};
    }
  }
  
  /// 终止指定名称的进程
  static Future<bool> terminateProcess(String processName) async {
    try {
      // 在Windows上使用taskkill命令终止进程
      final result = await runExecutableArguments('taskkill', ['/IM', processName, '/F']);
      return result.exitCode == 0;
    } catch (e) {
      return false;
    }
  }
  
  /// 检查游戏是否正在运行
  static Future<bool> checkGameStatus() async {
    try {
      // 在Windows上使用tasklist命令检查进程
      final result = await runExecutableArguments('tasklist', ['/FI', 'IMAGENAME eq $GAME_PROCESS_NAME']);
      return result.stdout.toString().contains(GAME_PROCESS_NAME);
    } catch (e) {
      return false;
    }
  }
  
  /// 重启Steam游戏
  static Future<Map<String, dynamic>> restartSteamGame() async {
    try {
      // 先尝试终止游戏进程
      await terminateProcess(GAME_PROCESS_NAME);
      
      // 等待2秒确保进程已结束
      await Future.delayed(Duration(seconds: 2));
      
      // 启动游戏
      final launchResult = await launchSteamGame();
      
      if (launchResult['success'] == true) {
        return {'success': true, 'message': '游戏重启成功'};
      } else {
        return {'success': false, 'message': '重启失败: ${launchResult['message']}'};
      }
    } catch (e) {
      return {'success': false, 'message': '重启失败: ${e.toString()}'};
    }
  }
}
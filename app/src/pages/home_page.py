import flet as ft
import sys
import os
import subprocess
import psutil
import time
import asyncio

# 添加src目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.theme_manager import get_theme_colors


def heading(text, level=1, color=None):
    """
    创建标题文本
    
    Args:
        text (str): 标题文本
        level (int): 标题级别 (1-6)
        color (str, optional): 文本颜色，默认使用主题颜色
        
    Returns:
        ft.Text: 配置好的标题文本控件
    """
    colors = get_theme_colors()
    if color is None:
        color = colors["text_primary"]
    
    # 根据标题级别设置大小和样式
    sizes = {1: 32, 2: 28, 3: 24, 4: 20, 5: 18, 6: 16}
    weights = {1: ft.FontWeight.BOLD, 2: ft.FontWeight.BOLD, 3: ft.FontWeight.BOLD,
               4: ft.FontWeight.NORMAL, 5: ft.FontWeight.NORMAL, 6: ft.FontWeight.NORMAL}
    
    return ft.Text(
        text,
        size=sizes.get(level, 16),
        weight=weights.get(level, ft.FontWeight.NORMAL),
        color=color,
        font_family="MiSans"
    )


def body(text, size=14, color=None, weight=ft.FontWeight.NORMAL):
    """
    创建正文文本
    
    Args:
        text (str): 正文文本
        size (int): 字体大小
        color (str, optional): 文本颜色，默认使用主题颜色
        weight (ft.FontWeight): 字体粗细
        
    Returns:
        ft.Text: 配置好的正文文本控件
    """
    colors = get_theme_colors()
    if color is None:
        color = colors["text_primary"]
        
    return ft.Text(
        text,
        size=size,
        color=color,
        weight=weight,
        font_family="MiSans"
    )


def caption(text, size=12, color=None):
    """
    创建说明文字
    
    Args:
        text (str): 说明文字
        size (int): 字体大小
        color (str, optional): 文本颜色，默认使用主题颜色
        
    Returns:
        ft.Text: 配置好的说明文字控件
    """
    colors = get_theme_colors()
    if color is None:
        color = colors["text_secondary"]
        
    return ft.Text(
        text,
        size=size,
        color=color,
        font_family="MiSans"
    )


def scrollable_page(
    content,
    scroll=ft.ScrollMode.AUTO,
    alignment=ft.MainAxisAlignment.START,
    horizontal_alignment=ft.CrossAxisAlignment.START,
    spacing=10,
    padding=20,
    auto_scroll=False,
    **kwargs
):
    """
    创建一个可滚动的页面布局的便捷函数
    
    Args:
        content: 页面内容（可以是控件列表或单个控件）
        scroll: 滚动模式
        alignment: 主轴对齐方式
        horizontal_alignment: 交叉轴对齐方式
        spacing: 控件间距
        padding: 页面内边距
        auto_scroll: 是否自动滚动到底部
        **kwargs: 其他参数
        
    Returns:
        ft.Column: 配置好的可滚动列布局
    """
    # 如果内容不是列表，转换为列表
    if not isinstance(content, list):
        content = [content]
        
    # 创建可滚动的列布局
    scrollable_column = ft.Column(
        controls=content,
        scroll=scroll,
        alignment=alignment,
        horizontal_alignment=horizontal_alignment,
        spacing=spacing,
        auto_scroll=auto_scroll,
        **kwargs
    )
    
    # 如果指定了padding，则将其包装在一个容器中
    if padding:
        return ft.Container(
            content=scrollable_column,
            padding=padding
        )
    
    return scrollable_column


def launch_steam_game(steam_id):
    """启动Steam游戏"""
    try:
        subprocess.run(["start", f"steam://run/{steam_id}"], shell=True)
        return True, "游戏启动成功"
    except Exception as e:
        return False, f"启动失败: {str(e)}"


def terminate_process(process_name):
    """终止指定名称的进程"""
    terminated = False
    for proc in psutil.process_iter(['pid', 'name']):
        try:
            if proc.info['name'] == process_name:
                proc.terminate()
                proc.wait(timeout=5)  # 等待最多5秒
                terminated = True
        except (psutil.NoSuchProcess, psutil.TimeoutExpired, psutil.AccessDenied):
            pass
    return terminated


def restart_steam_game(steam_id, process_name):
    """重启Steam游戏"""
    try:
        # 先尝试终止游戏进程
        terminate_process(process_name)
        time.sleep(2)  # 等待2秒确保进程已结束
        
        # 启动游戏
        success, message = launch_steam_game(steam_id)
        return success, message if success else f"重启失败: {message}"
    except Exception as e:
        return False, f"重启失败: {str(e)}"


def home_page_view(page: ft.Page):
    """主页视图"""
    colors = get_theme_colors()
    
    # 定义游戏信息
    GAME_STEAM_ID = "3167020"
    GAME_PROCESS_NAME = "Duckov.exe"
    
    # 创建状态文本引用
    status_text = ft.Text("", size=14, color=colors["text_secondary"], font_family="MiSans")
    
    def show_status(message):
        """显示状态信息"""
        status_text.value = message
        page.update()
    
    def clear_status():
        """清除状态信息"""
        status_text.value = ""
        page.update()
    
    def check_game_status():
        """检查游戏是否正在运行"""
        for proc in psutil.process_iter(['name']):
            try:
                if proc.info['name'] == GAME_PROCESS_NAME:
                    return True
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        return False
    
    def update_button_text():
        """根据游戏状态更新按钮文本"""
        if check_game_status():
            launch_button.content = ft.Row(
                [
                    ft.Icon(name=ft.Icons.STOP, color=colors["on_primary"]),
                    ft.Text("停止游戏", font_family="MiSans", color=colors["on_primary"], size=14)
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=5,
            )
        else:
            launch_button.content = ft.Row(
                [
                    ft.Icon(name=ft.Icons.PLAY_ARROW, color=colors["on_primary"]),
                    ft.Text("启动游戏", font_family="MiSans", color=colors["on_primary"], size=14)
                ],
                alignment=ft.MainAxisAlignment.CENTER,
                spacing=5,
            )
        page.update()
    
    async def periodic_update():
        """定期更新按钮状态"""
        while True:
            update_button_text()
            await asyncio.sleep(2)  # 每2秒检查一次
    
    async def on_launch_click_async():
        """异步处理启动/停止游戏按钮事件"""
        print(f"DEBUG: on_launch_click_async called, game status: {check_game_status()}")
        if check_game_status():
            # 游戏正在运行，需要停止游戏
            show_status("正在停止游戏...")
            try:
                # 执行停止操作
                page.run_thread(terminate_process, GAME_PROCESS_NAME)
                show_status("游戏已停止")
                # 1秒后清除状态
                await asyncio.sleep(1)
                clear_status()
            except Exception as ex:
                print(f"DEBUG: Exception in stop game: {ex}")
                show_status(f"停止游戏时发生错误: {str(ex)}")
        else:
            # 游戏未运行，需要启动游戏
            show_status("正在启动游戏...")
            try:
                # 执行启动操作
                page.run_thread(launch_steam_game, GAME_STEAM_ID)
                # 不管结果如何，都显示成功消息，因为游戏确实启动了
                show_status("游戏启动指令已发送")
                # 1秒后清除状态
                await asyncio.sleep(1)
                clear_status()
            except Exception as ex:
                print(f"DEBUG: Exception in start game: {ex}")
                show_status(f"启动游戏时发生错误: {str(ex)}")
        
        # 更新按钮状态
        update_button_text()
    
    def on_launch_click(e):
        """启动/停止游戏按钮事件"""
        page.run_task(on_launch_click_async)
    
    async def on_restart_click_async():
        """异步处理重启游戏按钮事件"""
        print("DEBUG: on_restart_click_async called")
        show_status("正在重启游戏...")
        try:
            # 执行重启操作
            page.run_thread(restart_steam_game, GAME_STEAM_ID, GAME_PROCESS_NAME)
            # 不管结果如何，都显示成功消息，因为游戏确实启动了
            show_status("游戏重启指令已发送")
            # 1秒后清除状态
            await asyncio.sleep(1)
            clear_status()
        except Exception as ex:
            print(f"DEBUG: Exception in restart game: {ex}")
            show_status(f"重启游戏时发生错误: {str(ex)}")
        
        # 更新按钮状态
        update_button_text()
    
    def on_restart_click(e):
        """重启游戏按钮事件"""
        page.run_task(on_restart_click_async)
    
    # 创建启动游戏按钮
    launch_button = ft.ElevatedButton()
    launch_button.content = ft.Row(
        [
            ft.Icon(name=ft.Icons.PLAY_ARROW, color=colors["on_primary"]),
            ft.Text("启动游戏", font_family="MiSans", color=colors["on_primary"], size=14)
        ],
        alignment=ft.MainAxisAlignment.CENTER,
        spacing=5,
    )
    launch_button.on_click = on_launch_click
    launch_button.style = ft.ButtonStyle(
        bgcolor=colors["primary"],
        padding=ft.Padding(20, 15, 20, 15)
    )
    
    # 创建主页内容
    content = [
        heading("欢迎使用Duckov Mod Manager", level=1),
        body("这是一个逃离鸭科夫的模组管理工具，可以帮助您轻松管理游戏模组。"),
        
        ft.Divider(height=20),

        heading("游戏控制", level=2),
        body("快速启动或重启您的游戏"),

        ft.Row(
            [
                launch_button,
                ft.ElevatedButton(
                    content=ft.Row(
                        [
                            ft.Icon(name=ft.Icons.RESTART_ALT, color=colors["on_secondary"]),
                            ft.Text("重启游戏", font_family="MiSans", color=colors["on_secondary"], size=14)
                        ],
                        alignment=ft.MainAxisAlignment.CENTER,
                        spacing=5,
                    ),
                    on_click=on_restart_click,
                    style=ft.ButtonStyle(
                        bgcolor=colors["secondary"],
                        padding=ft.Padding(20, 15, 20, 15)
                    )
                )
            ],
            spacing=10
        ),
        
        # 添加状态文本显示区域
        status_text,

        ft.Divider(height=20),
        
        heading("开始使用", level=2),
        body("点击左侧导航栏中的选项来开始使用不同的功能。"),
        
        ft.Divider(height=20),
        
        caption("版本 0.1.1")
    ]
    
    # 使用可滚动页面布局，默认左对齐
    scrollable_content = scrollable_page(
        content=content,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    # 初始化按钮状态
    update_button_text()
    
    # 启动定期更新任务
    page.run_task(periodic_update)
    
    return scrollable_content

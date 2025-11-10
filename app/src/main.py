import flet as ft

import sys
import os

# 添加src目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# 导入页面模块
from pages import home_page, mods_page, settings_page
from pages.steam_workshop_page import steam_workshop_view
from pages.update_page import update_page_view
from services.app_routes import AppRoutes, NAVIGATION_ITEMS
from services.theme_manager import get_theme_colors
from services.config_manager import config_manager
from services.version_manager import version_manager


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


def create_app_layout(page: ft.Page, title: str = "Application"):
    """创建应用程序布局的便捷函数"""
    from services.app_layout import create_app_layout
    return create_app_layout(page, title)


def main(page: ft.Page):
    # 设置页面标题
    page.title = "Duckov Mod Manager"
    
    # 设置窗口大小
    page.window_width = 1000
    page.window_height = 700
    page.window_resizable = True
    
    # 设置自定义字体
    page.fonts = {
        "MiSans": "assets/fonts/MiSans-Regular.ttf"
    }
    
    # 应用主题设置并使用自定义字体
    theme_colors = get_theme_colors()
    page.bgcolor = theme_colors["background"]
    
    # 设置默认字体族
    page.theme = ft.Theme(
        font_family="MiSans"
    )
    
    # 打印字体加载日志
    print("字体加载状态:")
    print(f"- MiSans 字体已注册: {'MiSans' in page.fonts}")
    print(f"- 字体路径: {page.fonts.get('MiSans', '未找到')}")
    print("- 正在尝试应用MiSans字体到整个应用...")
    
    # 初始化应用布局
    app_layout = create_app_layout(page, "Duckov Mod Manager")
    
    # 存储当前路由
    current_route = AppRoutes.HOME

    # 路由处理函数
    def route_change(e):
        nonlocal current_route
        current_route = e.route if e.route else AppRoutes.HOME
        
        # 根据路由显示对应页面
        if current_route == AppRoutes.HOME:
            content = home_page.home_page_view(page)
        elif current_route == AppRoutes.MODS:
            content = mods_page.mods_page_view(page)
        elif current_route == AppRoutes.STEAM_WORKSHOP:
            content = steam_workshop_view(page)
        elif current_route == AppRoutes.SETTINGS:
            content = settings_page.settings_page_view(page)
        elif current_route == AppRoutes.UPDATE:
            content = update_page_view(page)
        else:
            content = ft.Column([
                heading("页面未找到", level=1),
                body("抱歉，您访问的页面不存在。")
            ])
        
        app_layout.set_content(content)
    
    # 导航处理函数
    def navigate_to(route):
        page.go(route)
    
    # 自动检查更新功能
    def auto_check_for_updates():
        """启动时自动检查更新"""
        # 检查是否启用了自动更新检查
        if config_manager.get("auto_update", True):
            print("自动检查更新已启用，正在检查更新...")
            
            def check_update_task():
                try:
                    # 检查更新
                    update_result = version_manager.check_for_updates()
                    
                    # 如果有更新且不是被跳过的版本，则跳转到更新页面
                    if update_result.get('has_update'):
                        skipped_version = config_manager.get("skip_version")
                        latest_version = update_result.get('latest_version')
                        
                        # 如果没有跳过该版本，则显示更新提示
                        if skipped_version != latest_version:
                            # 将更新信息存储到会话中
                            page.session.set("update_info", update_result)
                            # 跳转到更新页面
                            page.go("/update")
                            page.update()
                            print(f"发现新版本: {latest_version}")
                        else:
                            print(f"发现新版本 {latest_version}，但已被用户跳过")
                    else:
                        print("当前已是最新版本")
                        
                except Exception as e:
                    print(f"自动检查更新时发生错误: {e}")
            
            # 在后台线程中执行检查更新任务
            page.run_thread(check_update_task)
        else:
            print("自动检查更新已禁用")

    # 为侧边栏添加导航项
    for item_data in NAVIGATION_ITEMS:
        # 修复图标引用问题
        icon_name = item_data["icon"].upper()
        icon = getattr(ft.Icons, icon_name, None)
        nav_item = {
            "text": item_data["text"],
            "icon": icon,
            "route": item_data["route"],
            "on_click": lambda e, route=item_data["route"]: navigate_to(route)
        }
        app_layout.add_sidebar_item(nav_item)
    
    # 设置路由变化监听器
    page.on_route_change = route_change
    
    # 初始化导航到主页
    page.go(AppRoutes.HOME)
    
    # 在应用启动后稍延迟执行自动检查更新
    def delayed_auto_check():
        import time
        time.sleep(2)  # 等待2秒确保UI加载完成
        auto_check_for_updates()
    
    # 启动自动检查更新线程
    import threading
    auto_check_thread = threading.Thread(target=delayed_auto_check, daemon=True)
    auto_check_thread.start()


ft.app(main)
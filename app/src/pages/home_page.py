# pages/home_page.py
import flet as ft
import sys
import os

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


def home_page_view(page: ft.Page):
    """主页视图"""
    colors = get_theme_colors()
    
    # 创建主页内容
    content = [
        heading("欢迎使用Duckov 模组管理器", level=1),
        body("这是一个现代化的模组管理工具，可以帮助您轻松管理游戏模组。"),
        
        ft.Divider(height=20),
        
        heading("功能特点", level=2),
        ft.ResponsiveRow(
            controls=[
                ft.Column(
                    controls=[
                        ft.Icon(ft.Icons.FOLDER_OPEN, size=40, color=colors["primary"]),
                        body("模组浏览", size=18),
                        caption("浏览和查看已安装的模组")
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    col={"xs": 12, "sm": 6, "md": 4}
                ),
                ft.Column(
                    controls=[
                        ft.Icon(ft.Icons.DOWNLOAD, size=40, color=colors["primary"]),
                        body("一键下载", size=18),
                        caption("从Steam创意工坊下载模组")
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    col={"xs": 12, "sm": 6, "md": 4}
                ),
                ft.Column(
                    controls=[
                        ft.Icon(ft.Icons.SETTINGS, size=40, color=colors["primary"]),
                        body("配置管理", size=18),
                        caption("管理模组配置和设置")
                    ],
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                    col={"xs": 12, "sm": 6, "md": 4}
                )
            ],
            spacing=20,
            run_spacing=20
        ),
        
        ft.Divider(height=20),
        
        heading("开始使用", level=2),
        body("点击左侧导航栏中的选项来开始使用不同的功能。"),
        
        ft.Divider(height=20),
        
        caption("版本 0.1.0")
    ]
    
    # 使用可滚动页面布局，默认左对齐
    scrollable_content = scrollable_page(
        content=content,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    return scrollable_content
# pages/mods_page.py
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


def primary_button(text, on_click=None, width=None, height=None):
    """
    创建主要操作按钮
    
    Args:
        text (str): 按钮文本
        on_click (callable): 点击事件处理函数
        width (int, optional): 按钮宽度
        height (int, optional): 按钮高度
        
    Returns:
        ft.ElevatedButton: 配置好的主要按钮
    """
    colors = get_theme_colors()
    return ft.ElevatedButton(
        text=text,
        on_click=on_click,
        width=width,
        height=height,
        style=ft.ButtonStyle(
            color=ft.Colors.WHITE,
            bgcolor=colors["primary"],
            text_style=ft.TextStyle(font_family="MiSans")
        ),
    )


def secondary_button(text, on_click=None, width=None, height=None):
    """
    创建次要操作按钮
    
    Args:
        text (str): 按钮文本
        on_click (callable): 点击事件处理函数
        width (int, optional): 按钮宽度
        height (int, optional): 按钮高度
        
    Returns:
        ft.OutlinedButton: 配置好的次要按钮
    """
    colors = get_theme_colors()
    return ft.OutlinedButton(
        text=text,
        on_click=on_click,
        width=width,
        height=height,
        style=ft.ButtonStyle(
            color=colors["primary"],
            side=ft.BorderSide(1, colors["primary"]),
            text_style=ft.TextStyle(font_family="MiSans")
        ),
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


def mods_page_view(page: ft.Page):
    """模组管理页面视图"""
    # 获取主题颜色
    colors = get_theme_colors()
    
    # 创建模组表格
    mods_table = ft.DataTable(
        columns=[
            ft.DataColumn(heading("名称", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("版本", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("状态", level=4, color=colors["text_primary"])),
            ft.DataColumn(heading("操作", level=4, color=colors["text_primary"])),
        ],
        rows=[
            ft.DataRow(
                cells=[
                    ft.DataCell(body("模组1")),
                    ft.DataCell(body("1.0.0")),
                    ft.DataCell(body("已启用")),
                    ft.DataCell(
                        ft.Row([
                            primary_button("禁用", width=80, height=30),
                            secondary_button("删除", width=80, height=30)
                        ])
                    ),
                ]
            ),
            ft.DataRow(
                cells=[
                    ft.DataCell(body("模组2")),
                    ft.DataCell(body("2.1.0")),
                    ft.DataCell(body("已禁用")),
                    ft.DataCell(
                        ft.Row([
                            primary_button("启用", width=80, height=30),
                            secondary_button("删除", width=80, height=30)
                        ])
                    ),
                ]
            ),
        ] + [
            ft.DataRow(
                cells=[
                    ft.DataCell(body(f"模组{i}")),
                    ft.DataCell(body(f"{i}.{i//2}.{i%3}")),
                    ft.DataCell(body("已启用" if i % 2 == 0 else "已禁用")),
                    ft.DataCell(
                        ft.Row([
                            primary_button("禁用" if i % 2 == 0 else "启用", width=80, height=30),
                            secondary_button("删除", width=80, height=30)
                        ])
                    ),
                ]
            ) for i in range(3, 20)  # 添加更多行以测试滚动
        ],
        border=ft.border.all(2, colors["text_secondary"]),
        border_radius=10,
        vertical_lines=ft.border.BorderSide(1, colors["text_secondary"]),
        horizontal_lines=ft.border.BorderSide(1, colors["text_secondary"]),
        heading_row_color=colors["surface"],
    )
    
    # 创建页面内容
    content = [
        heading("模组管理", level=1),
        body("在此页面您可以管理您的游戏模组。"),
        
        ft.Divider(height=20),
        
        ft.Row(
            controls=[
                primary_button("添加模组"),
                secondary_button("刷新列表")
            ]
        ),
        
        ft.Divider(height=20),
        
        mods_table,
        
        ft.Divider(height=20),
        
        caption("总共 {} 个模组".format(19))
    ]
    
    # 使用可滚动页面布局，默认左对齐
    scrollable_content = scrollable_page(
        content=content,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    return scrollable_content
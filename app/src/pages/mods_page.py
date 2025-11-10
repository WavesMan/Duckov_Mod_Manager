# pages/mods_page.py
import flet as ft
import sys
import os

# 添加src目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.theme_manager import get_theme_colors
from services.mod_manager import mod_manager


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


def _create_mod_card(mod_info: dict, page: ft.Page) -> ft.Control:
    """创建单个模组卡片"""
    colors = get_theme_colors()
    
    # 检查模组是否已启用
    is_enabled = mod_manager.is_mod_enabled(mod_info['id'])
    print(f"模组 {mod_info['id']} 启用状态: {is_enabled}")
    
    # 模组标题（优先使用display_name，其次是name）
    mod_name = mod_info.get('display_name', mod_info.get('name', f'模组 {mod_info["id"]}'))
    title = heading(mod_name, level=4)
    
    # 模组信息
    id_text = body(f"ID: {mod_info['id']}")
    size_text = body(f"大小: {mod_info.get('size', '未知')}")
    
    # 模组描述
    description_text = caption(mod_info.get('description', '暂无描述'))
    
    # 状态信息
    status_color = colors["primary"] if is_enabled else colors["error"]
    status_text = caption("已启用" if is_enabled else "已禁用", color=status_color)
    
    # 查找预览图
    preview_image = None
    preview_path = os.path.join(mod_info['path'], 'preview.png')
    if os.path.exists(preview_path):
        preview_image = ft.Image(
            src=preview_path,
            width=100,
            height=100,
            fit=ft.ImageFit.CONTAIN,
        )
    else:
        # 如果没有preview.png，使用占位符图标
        preview_image = ft.Icon(ft.Icons.FOLDER, size=60, color=colors["text_secondary"])
    
    # 左侧图片部分
    image_container = ft.Container(
        content=preview_image,
        width=100,
        height=100,
        alignment=ft.alignment.center,
    )
    
    # 右侧详细信息部分
    # 为描述文本创建可滚动容器
    description_container = ft.Container(
        content=ft.Column(
            controls=[description_text],
            spacing=4,
            scroll=ft.ScrollMode.AUTO,
            expand=True,
        ),
        height=40,  # 固定描述区域高度
        expand=True,
    )
    
    details_column = ft.Column(
        controls=[
            title,
            id_text,
            size_text,
            description_container,
            status_text
        ],
        spacing=4,
        expand=True,
    )
    
    # 启用/禁用按钮
    def toggle_mod(e):
        # 重新检查模组状态（避免状态不同步）
        current_enabled = mod_manager.is_mod_enabled(mod_info['id'])
        print(f"切换模组 {mod_info['id']} 状态，当前状态: {current_enabled}")
        if current_enabled:
            # 禁用模组
            print(f"尝试禁用模组 {mod_info['id']}")
            if mod_manager.disable_mod(mod_info['id']):
                # 更新UI
                print("禁用成功，更新UI")
                status_text.value = "已禁用"
                status_text.color = colors["error"]
                toggle_button.text = "启用"
                toggle_button.style = ft.ButtonStyle(
                    color=ft.Colors.WHITE,
                    bgcolor=colors["primary"],
                    text_style=ft.TextStyle(font_family="MiSans")
                )
                page.snack_bar = ft.SnackBar(
                    content=ft.Text(f"模组 {mod_name} 已禁用"),
                    bgcolor=ft.Colors.GREEN,
                )
            else:
                page.snack_bar = ft.SnackBar(
                    content=ft.Text(f"禁用模组 {mod_name} 失败"),
                    bgcolor=ft.Colors.RED,
                )
        else:
            # 启用模组
            print(f"尝试启用模组 {mod_info['id']}")
            if mod_manager.enable_mod(mod_info['id']):
                # 更新UI
                print("启用成功，更新UI")
                status_text.value = "已启用"
                status_text.color = colors["primary"]
                toggle_button.text = "禁用"
                toggle_button.style = ft.ButtonStyle(
                    color=ft.Colors.WHITE,
                    bgcolor=colors["error"],
                    text_style=ft.TextStyle(font_family="MiSans")
                )
                page.snack_bar = ft.SnackBar(
                    content=ft.Text(f"模组 {mod_name} 已启用"),
                    bgcolor=ft.Colors.GREEN,
                )
            else:
                page.snack_bar = ft.SnackBar(
                    content=ft.Text(f"启用模组 {mod_name} 失败"),
                    bgcolor=ft.Colors.RED,
                )
        
        page.snack_bar.open = True
        page.update()
    
    toggle_button = ft.ElevatedButton(
        "禁用" if is_enabled else "启用",
        width=100,
        height=30,
        style=ft.ButtonStyle(
            color=ft.Colors.WHITE,
            bgcolor=colors["error"] if is_enabled else colors["primary"],
            text_style=ft.TextStyle(font_family="MiSans")
        ),
        on_click=toggle_mod
    )
    
    # 删除按钮（暂不实现）
    delete_button = secondary_button("删除", width=100, height=30)
    
    # 操作按钮
    actions = [
        toggle_button,
        delete_button
    ]
    
    # 按钮行
    buttons_row = ft.Row(
        controls=actions,
        spacing=5,
        alignment=ft.MainAxisAlignment.END,
    )
    
    # 组合左右两部分
    content_row = ft.Row(
        controls=[
            image_container,
            ft.Column(
                controls=[
                    details_column,
                    buttons_row
                ],
                spacing=10,
                expand=True,
            )
        ],
        spacing=10,
        expand=True,
    )
    
    # 创建卡片
    card = ft.Card(
        content=ft.Container(
            content=content_row,
            padding=10,
        ),
        margin=5,
    )
    
    return card


def mods_page_view(page: ft.Page):
    """模组管理页面视图"""
    # 获取主题颜色
    colors = get_theme_colors()
    
    # 创建一个引用，用于更新模组列表
    mod_cards_container = ft.Column(spacing=10)
    
    def refresh_mods_list(search_term=""):
        """刷新模组列表"""
        # 清空现有内容
        mod_cards_container.controls.clear()
        
        # 获取已下载的模组
        downloaded_mods = mod_manager.get_downloaded_mods()
        
        # 如果有搜索词，进行过滤
        if search_term:
            filtered_mods = []
            for mod_info in downloaded_mods:
                # 获取模组名称和描述
                mod_name = mod_info.get('display_name', mod_info.get('name', f'模组 {mod_info["id"]}'))
                mod_description = mod_info.get('description', '')
                
                # 检查搜索词是否在名称或描述中
                if search_term.lower() in mod_name.lower() or search_term.lower() in mod_description.lower():
                    filtered_mods.append(mod_info)
            downloaded_mods = filtered_mods
        
        # 创建双列布局
        left_column = ft.Column(spacing=10, expand=True)
        right_column = ft.Column(spacing=10, expand=True)
        
        # 交替将模组卡片添加到左右两列
        for i, mod_info in enumerate(downloaded_mods):
            mod_card = _create_mod_card(mod_info, page)
            # 固定卡片尺寸
            mod_card.width = 500
            mod_card.height = 250
            if i % 2 == 0:
                left_column.controls.append(mod_card)
            else:
                right_column.controls.append(mod_card)
        
        # 如果没有模组，显示提示信息
        if not downloaded_mods:
            no_mods_content = ft.Column([
                ft.Icon(ft.Icons.FOLDER_OFF, size=64, color=colors["text_secondary"]),
                heading("未找到已下载的模组", level=3),
                body("请先在创意工坊页面下载模组"),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=20)
            left_column.controls.append(no_mods_content)
        
        # 创建双列容器
        columns_row = ft.ResponsiveRow(
            controls=[
                ft.Container(content=left_column, col={"xs": 12, "sm": 12, "md": 6}),
                ft.Container(content=right_column, col={"xs": 12, "sm": 12, "md": 6}),
            ],
            spacing=10,
            expand=True
        )
        
        # 添加双列容器到主容器
        mod_cards_container.controls.append(columns_row)
        
        # 更新总计信息
        mod_count = len(downloaded_mods)
        count_text.value = f"总共 {mod_count} 个模组"
        
        page.update()
    
    # 搜索框处理函数
    def on_search_change(e):
        refresh_mods_list(e.control.value)
    
    # 创建搜索框
    search_box = ft.TextField(
        label="搜索模组...",
        on_change=on_search_change,
        width=300,
    )
    
    # 创建刷新按钮
    refresh_button = primary_button("刷新列表", on_click=lambda _: refresh_mods_list())
    
    # 创建总计文本
    count_text = caption("总共 0 个模组")
    
    # 创建页面内容
    content = [
        heading("模组管理", level=1),
        body("在此页面您可以管理已下载的游戏模组。"),
        
        ft.Divider(height=20),
        
        ft.Row([
            refresh_button,
            search_box,
        ], spacing=10),
        
        ft.Divider(height=20),
        
        mod_cards_container,
        
        ft.Divider(height=20),
        
        count_text
    ]
    
    # 首次加载时刷新模组列表
    refresh_mods_list()
    
    # 使用可滚动页面布局，默认左对齐
    scrollable_content = scrollable_page(
        content=content,
        horizontal_alignment=ft.CrossAxisAlignment.START
    )
    
    return scrollable_content

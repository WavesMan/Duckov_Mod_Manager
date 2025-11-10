# pages/update_page.py
import flet as ft
import logging
import webbrowser
from services.theme_manager import get_theme_colors
from services.config_manager import config_manager

logger = logging.getLogger(__name__)

def heading(text, level=1, color=None):
    """创建标题文本"""
    colors = get_theme_colors()
    if color is None:
        color = colors["text_primary"]
    
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
    """创建正文文本"""
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
    """创建说明文字"""
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
    """创建主要操作按钮"""
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
    """创建次要操作按钮"""
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

def update_page_view(page: ft.Page):
    """更新页面视图"""
    colors = get_theme_colors()
    
    # 获取会话中的更新信息
    update_info = page.session.get("update_info")
    
    # 如果没有提供更新信息或没有更新，则显示无更新的提示
    if not update_info or not update_info.get('has_update'):
        content = ft.Column(
            controls=[
                heading("版本检查", level=1),
                ft.Container(
                    content=ft.Row(
                        controls=[
                            ft.Icon(ft.Icons.CHECK_CIRCLE, color=colors["primary"], size=48),
                        ],
                        alignment=ft.MainAxisAlignment.CENTER
                    ),
                    margin=ft.margin.only(top=30)
                ),
                ft.Container(
                    content=ft.Text("当前已是最新版本", size=18, font_family="MiSans"),
                    margin=ft.margin.only(top=20),
                    alignment=ft.alignment.center
                ),
                ft.Container(
                    content=ft.Text(f"当前版本: v{config_manager.get('current_version', '0.1.0')}", 
                                  size=14, 
                                  font_family="MiSans",
                                  color=colors["text_secondary"]),
                    margin=ft.margin.only(top=10)
                ),
                ft.Container(
                    content=primary_button("返回设置", 
                                         on_click=lambda _: page.go("/settings"),
                                         width=120),
                    margin=ft.margin.only(top=40),
                    alignment=ft.alignment.center
                )
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            expand=True
        )
    else:
        # 显示更新信息
        def on_download_update(e):
            """下载更新"""
            try:
                download_url = update_info.get('download_url', '')
                if download_url:
                    webbrowser.open(download_url)
                    page.snack_bar = ft.SnackBar(
                        content=ft.Text("正在打开下载页面..."),
                        bgcolor=ft.Colors.GREEN,
                    )
                    page.snack_bar.open = True
                    page.update()
                else:
                    page.snack_bar = ft.SnackBar(
                        content=ft.Text("下载链接不可用"),
                        bgcolor=ft.Colors.RED,
                    )
                    page.snack_bar.open = True
                    page.update()
            except Exception as ex:
                logger.error(f"打开下载链接失败: {ex}")
                page.snack_bar = ft.SnackBar(
                    content=ft.Text("打开下载链接失败"),
                    bgcolor=ft.Colors.RED,
                )
                page.snack_bar.open = True
                page.update()

        def on_skip_version(e):
            """跳过此版本"""
            latest_version = update_info.get('latest_version')
            if latest_version:
                config_manager.set("skipped_version", latest_version)
                page.snack_bar = ft.SnackBar(
                    content=ft.Text(f"已跳过版本 {latest_version}"),
                    bgcolor=ft.Colors.BLUE,
                )
                page.snack_bar.open = True
                page.update()
            page.go("/settings")
        
        # 版本信息
        version_info = ft.Row(
            controls=[
                ft.Column(
                    controls=[
                        caption("当前版本", size=14),
                        body(f"v{update_info.get('current_version', 'Unknown')}", 
                             size=16, weight=ft.FontWeight.BOLD)
                    ],
                    spacing=5,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER
                ),
                ft.Icon(ft.Icons.ARROW_FORWARD, color=colors["text_secondary"]),
                ft.Column(
                    controls=[
                        caption("最新版本", size=14),
                        body(f"v{update_info.get('latest_version', 'Unknown')}", 
                             size=16, weight=ft.FontWeight.BOLD, color=colors["primary"])
                    ],
                    spacing=5,
                    horizontal_alignment=ft.CrossAxisAlignment.CENTER
                )
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=20
        )
        
        # 更新说明
        release_body = update_info.get('release_info', {}).get('body', '')
        if release_body:
            update_notes = ft.Column(
                controls=[
                    heading("更新内容", level=3),
                    ft.Container(
                        content=ft.Column([
                            ft.Markdown(
                                release_body,
                                selectable=True,
                                extension_set=ft.MarkdownExtensionSet.GITHUB_WEB,
                                code_theme="atom-one-dark",
                            )
                        ]),
                        padding=15,
                        border=ft.border.all(1, colors["divider"]),
                        border_radius=5,
                    )
                ],
                spacing=10,
            )
        else:
            update_notes = ft.Column(
                controls=[
                    heading("更新内容", level=3),
                    caption("暂无更新说明", size=14)
                ],
                spacing=10
            )
        
        # 创建主布局：标题+版本信息在顶部，更新内容在中间可滚动区域，按钮在底部
        main_layout = ft.Column(
            controls=[
                # 标题和版本信息部分（固定）
                ft.Column(
                    controls=[
                        heading("发现新版本", level=1),
                        ft.Container(
                            content=version_info,
                            margin=ft.margin.only(top=20)
                        ),
                    ],
                    spacing=10
                ),
                
                # 更新内容（占据剩余空间并可滚动）
                ft.Container(
                    content=scrollable_page(
                        content=update_notes,
                        horizontal_alignment=ft.CrossAxisAlignment.START,
                        expand=True
                    ),
                    expand=True
                ),
                
                # 操作按钮（固定在底部）
                ft.Container(
                    content=ft.Row(
                        controls=[
                            primary_button("下载更新", on_click=on_download_update, width=120),
                            secondary_button("跳过此版本", on_click=on_skip_version, width=120)
                        ],
                        spacing=15,
                        alignment=ft.MainAxisAlignment.CENTER
                    ),
                    margin=ft.margin.only(top=20)
                ),
                ft.Container(
                    content=ft.TextButton(
                        "稍后提醒我", 
                        on_click=lambda _: page.go("/settings"),
                        style=ft.ButtonStyle(
                            color=colors["text_secondary"]
                        )
                    ),
                    margin=ft.margin.only(top=10),
                    alignment=ft.alignment.center
                )
            ],
            expand=True,
            spacing=0
        )
        
        content = main_layout
    
    return ft.Container(
        content=content,
        padding=20,
        expand=True
    )
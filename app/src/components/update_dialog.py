# components/update_dialog.py
import flet as ft
import logging
from datetime import datetime
from services.theme_manager import get_theme_colors

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


class UpdateDialog:
    """更新检查对话框"""
    
    def __init__(self, page: ft.Page):
        self.page = page
        self.dialog = None
        self.on_update_callback = None
        self.on_skip_callback = None
        
    def show_update_dialog(self, update_info: dict, on_update=None, on_skip=None):
        """显示更新对话框"""
        self.on_update_callback = on_update
        self.on_skip_callback = on_skip
        
        colors = get_theme_colors()
        
        # 创建对话框内容
        content = self._create_dialog_content(update_info)
        
        # 创建对话框
        self.dialog = ft.AlertDialog(
            modal=True,
            title=heading("发现新版本", level=2),
            content=content,
            actions=self._create_dialog_actions(update_info),
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        # 显示对话框
        self.page.dialog = self.dialog
        self.dialog.open = True
        self.page.update()
        
        logger.info("更新对话框已显示")
    
    def show_no_update_dialog(self):
        """显示无更新对话框"""
        colors = get_theme_colors()
        
        content = ft.Column(
            controls=[
                ft.Icon(ft.Icons.CHECK_CIRCLE, color=colors["primary"], size=48),
                body("您当前使用的是最新版本", size=16, weight=ft.FontWeight.BOLD),
                body(f"当前版本: v{self._get_current_version()}"),
                body("无需更新", size=14, color=colors["text_secondary"])
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=15
        )
        
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("检查更新", level=2),
            content=content,
            actions=[
                ft.TextButton("确定", on_click=lambda e: self._close_dialog())
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        self.page.dialog = dialog
        dialog.open = True
        self.page.update()
        
        logger.info("无更新对话框已显示")
    
    def show_error_dialog(self, error_message: str):
        """显示错误对话框"""
        colors = get_theme_colors()
        
        content = ft.Column(
            controls=[
                ft.Icon(ft.Icons.ERROR, color=colors["error"], size=48),
                body("检查更新失败", size=16, weight=ft.FontWeight.BOLD),
                body(error_message, size=14, color=colors["text_secondary"])
            ],
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            spacing=15
        )
        
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("错误", level=2),
            content=content,
            actions=[
                ft.TextButton("重试", on_click=lambda e: self._retry_check()),
                ft.TextButton("取消", on_click=lambda e: self._close_dialog())
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        self.page.dialog = dialog
        dialog.open = True
        self.page.update()
        
        logger.info(f"错误对话框已显示: {error_message}")
    
    def _create_dialog_content(self, update_info: dict) -> ft.Column:
        """创建对话框内容"""
        colors = get_theme_colors()
        
        # 版本信息
        version_info = ft.Row(
            controls=[
                ft.Column(
                    controls=[
                        body("当前版本:", size=14, color=colors["text_secondary"]),
                        body(f"v{update_info.get('current_version', 'Unknown')}", 
                             size=16, weight=ft.FontWeight.BOLD)
                    ],
                    spacing=2
                ),
                ft.VerticalDivider(width=20),
                ft.Column(
                    controls=[
                        body("最新版本:", size=14, color=colors["text_secondary"]),
                        body(f"v{update_info.get('latest_version', 'Unknown')}", 
                             size=16, weight=ft.FontWeight.BOLD, color=colors["primary"])
                    ],
                    spacing=2
                )
            ],
            alignment=ft.MainAxisAlignment.CENTER,
            spacing=10
        )
        
        # 更新说明
        release_body = update_info.get('release_info', {}).get('body', '')
        if release_body:
            update_notes = ft.Column(
                controls=[
                    body("更新说明:", size=14, weight=ft.FontWeight.BOLD),
                    ft.Container(
                        content=ft.Markdown(
                            release_body,
                            selectable=True,
                            extension_set=ft.MarkdownExtensionSet.GITHUB_WEB
                        ),
                        padding=10,
                        border=ft.border.all(1, colors["divider"]),
                        border_radius=5,
                        height=200,
                        expand=True
                    )
                ],
                spacing=8
            )
        else:
            update_notes = body("暂无更新说明", size=14, color=colors["text_secondary"])
        
        # 发布日期
        release_date = update_info.get('release_info', {}).get('published_at', '')
        if release_date:
            try:
                date_obj = datetime.fromisoformat(release_date.replace('Z', '+00:00'))
                formatted_date = date_obj.strftime("%Y年%m月%d日")
                date_info = body(f"发布日期: {formatted_date}", size=12, color=colors["text_secondary"])
            except:
                date_info = body(f"发布日期: {release_date}", size=12, color=colors["text_secondary"])
        else:
            date_info = body("", size=12)
        
        return ft.Column(
            controls=[
                version_info,
                ft.Divider(height=20),
                update_notes,
                date_info
            ],
            spacing=15,
            scroll=ft.ScrollMode.AUTO,
            height=350
        )
    
    def _create_dialog_actions(self, update_info: dict) -> list:
        """创建对话框操作按钮"""
        actions = [
            secondary_button("暂不更新", on_click=lambda e: self._skip_update(update_info)),
            primary_button("立刻更新", on_click=lambda e: self._perform_update(update_info))
        ]
        return actions
    
    def _get_current_version(self) -> str:
        """获取当前版本"""
        from services.config_manager import config_manager
        return config_manager.get("current_version", "0.1.1")
    
    def _perform_update(self, update_info: dict):
        """执行更新操作"""
        logger.info("用户选择立刻更新")
        
        # 关闭对话框
        self._close_dialog()
        
        # 打开下载页面
        download_url = update_info.get('download_url', '')
        if download_url:
            from services.version_manager import version_manager
            version_manager.open_download_page(download_url)
        
        # 调用回调函数
        if self.on_update_callback:
            self.on_update_callback(update_info)
    
    def _skip_update(self, update_info: dict):
        """跳过当前版本更新"""
        logger.info("用户选择暂不更新")
        
        # 关闭对话框
        self._close_dialog()
        
        # 记录跳过的版本
        latest_version = update_info.get('latest_version')
        if latest_version:
            from services.config_manager import config_manager
            config_manager.set("skip_version", latest_version)
            logger.info(f"已跳过版本: {latest_version}")
        
        # 调用回调函数
        if self.on_skip_callback:
            self.on_skip_callback(update_info)
    
    def _retry_check(self):
        """重试检查更新"""
        logger.info("用户选择重试检查更新")
        self._close_dialog()
        
        # 触发重试回调
        if hasattr(self, 'on_retry_callback') and self.on_retry_callback:
            self.on_retry_callback()
    
    def _close_dialog(self):
        """关闭对话框"""
        if self.dialog:
            self.dialog.open = False
            self.page.update()
            logger.info("对话框已关闭")
# BaseComponents/textComponents.py
import flet as ft
from .themeManager import get_theme_colors


class TextAlign:
    """文本对齐方式的枚举类，使用Flet的枚举类型"""
    LEFT = ft.TextAlign.LEFT
    CENTER = ft.TextAlign.CENTER
    RIGHT = ft.TextAlign.RIGHT
    JUSTIFY = ft.TextAlign.JUSTIFY


class TextWeight:
    """字体粗细枚举类"""
    NORMAL = ft.FontWeight.NORMAL
    BOLD = ft.FontWeight.BOLD
    W_100 = ft.FontWeight.W_100
    W_200 = ft.FontWeight.W_200
    W_300 = ft.FontWeight.W_300
    W_400 = ft.FontWeight.W_400
    W_500 = ft.FontWeight.W_500
    W_600 = ft.FontWeight.W_600
    W_700 = ft.FontWeight.W_700
    W_800 = ft.FontWeight.W_800
    W_900 = ft.FontWeight.W_900


class BaseText:
    """基础文本组件类，支持多种对齐方式"""

    @staticmethod
    def create_text(text, size=16, color=None, align=ft.TextAlign.LEFT, weight=ft.FontWeight.NORMAL):
        """创建基础文本组件

        Args:
            text: 文本内容
            size: 字体大小
            color: 字体颜色
            align: 对齐方式 (ft.TextAlign.LEFT/CENTER/RIGHT/JUSTIFY)
            weight: 字体粗细
        """
        # 如果没有指定颜色，则使用主题中的主要文本颜色
        if color is None:
            Colors = get_theme_colors()
            color = Colors["text_primary"]
            
        return ft.Text(
            value=text,
            size=size,
            color=color,
            text_align=align,
            weight=weight
        )


class Layout:
    """布局组件类，用于快速创建不同对齐方式的文本容器"""

    @staticmethod
    def create_container(content, alignment=ft.alignment.center_left, expand=True, bgcolor=None, **kwargs):
        """创建容器

        Args:
            content: 内容控件
            alignment: 对齐方式 (ft.alignment.center/left/top_right等)
            expand: 是否扩展填充
            bgcolor: 背景颜色
            **kwargs: 其他容器参数
        """
        # 如果没有指定背景色，则使用主题中的表面颜色
        if bgcolor is None:
            Colors = get_theme_colors()
            bgcolor = Colors["surface"]
            
        return ft.Container(
            content=content,
            alignment=alignment,
            expand=expand,
            bgcolor=bgcolor,
            **kwargs
        )

    @staticmethod
    def center_text(text, size=16, color=None, **container_kwargs):
        """创建居中文本

        Args:
            text: 文本内容或ft.Text对象
            size: 字体大小
            color: 字体颜色
            **container_kwargs: 容器额外参数
        """
        if isinstance(text, str):
            text_obj = BaseText.create_text(text, size, color, ft.TextAlign.CENTER)
        else:
            text_obj = text

        return Layout.create_container(
            content=text_obj,
            alignment=ft.alignment.center,
            bgcolor=ft.Colors.TRANSPARENT,  # 显式设置透明背景
            **container_kwargs
        )

    @staticmethod
    def right_text(text, size=16, color=None, **container_kwargs):
        """创建居右文本

        Args:
            text: 文本内容或ft.Text对象
            size: 字体大小
            color: 字体颜色
            **container_kwargs: 容器额外参数
        """
        if isinstance(text, str):
            text_obj = BaseText.create_text(text, size, color, ft.TextAlign.RIGHT)
        else:
            text_obj = text

        return Layout.create_container(
            content=text_obj,
            alignment=ft.alignment.center_right,
            bgcolor=ft.Colors.TRANSPARENT,  # 显式设置透明背景
            **container_kwargs
        )

    @staticmethod
    def left_text(text, size=16, color=None, **container_kwargs):
        """创建居左文本

        Args:
            text: 文本内容或ft.Text对象
            size: 字体大小
            color: 字体颜色
            **container_kwargs: 容器额外参数
        """
        if isinstance(text, str):
            text_obj = BaseText.create_text(text, size, color, ft.TextAlign.LEFT)
        else:
            text_obj = text

        return Layout.create_container(
            content=text_obj,
            alignment=ft.alignment.center_left,
            bgcolor=ft.Colors.TRANSPARENT,  # 显式设置透明背景
            **container_kwargs
        )

    @staticmethod
    def create_text_block(text, size=16, color=None, text_align=ft.TextAlign.LEFT, **container_kwargs):
        """创建带文本对齐控制的文本块
        
        Args:
            text: 文本内容或ft.Text对象
            size: 字体大小
            color: 字体颜色
            text_align: 文本对齐方式
            **container_kwargs: 容器额外参数
        """
        if isinstance(text, str):
            text_obj = BaseText.create_text(text, size, color, text_align)
        else:
            text_obj = text
            
        # 根据文本对齐方式设置容器对齐
        alignment_map = {
            ft.TextAlign.LEFT: ft.alignment.center_left,
            ft.TextAlign.CENTER: ft.alignment.center,
            ft.TextAlign.RIGHT: ft.alignment.center_right,
            ft.TextAlign.JUSTIFY: ft.alignment.center_left,
        }
        
        return Layout.create_container(
            content=text_obj,
            alignment=alignment_map.get(text_align, ft.alignment.center_left),
            bgcolor=ft.Colors.TRANSPARENT,  # 显式设置透明背景
            **container_kwargs
        )


class TextStyle:
    """文本样式类，提供预定义的文本样式"""

    @staticmethod
    def heading(text, level=1, color=None):
        """创建标题文本

        Args:
            text: 标题文本
            level: 标题级别 (1-6)
            color: 字体颜色
        """
        # 如果没有指定颜色，则使用主题中的主要文本颜色
        if color is None:
            Colors = get_theme_colors()
            color = Colors["text_primary"]
            
        sizes = {1: 32, 2: 28, 3: 24, 4: 20, 5: 16, 6: 14}
        return BaseText.create_text(
            text,
            size=sizes.get(level, 16),
            color=color,
            weight=ft.FontWeight.BOLD
        )

    @staticmethod
    def caption(text, color=None):
        """创建说明文字

        Args:
            text: 说明文字
            color: 字体颜色
        """
        # 如果没有指定颜色，则使用主题中的次要文本颜色
        if color is None:
            Colors = get_theme_colors()
            color = Colors["text_secondary"]
            
        return BaseText.create_text(
            text,
            size=12,
            color=color
        )

    @staticmethod
    def body(text, size=14, color=None):
        """创建正文文本

        Args:
            text: 正文文本
            size: 字体大小
            color: 字体颜色
        """
        # 如果没有指定颜色，则使用主题中的主要文本颜色
        if color is None:
            Colors = get_theme_colors()
            color = Colors["text_primary"]
            
        return BaseText.create_text(text, size=size, color=color)

    @staticmethod
    def link(text, url=None, on_click=None, underline=True):
        """创建链接文本

        Args:
            text: 链接文本
            url: 链接地址
            on_click: 点击事件处理函数
            underline: 是否显示下划线
        """
        Colors = get_theme_colors()
        
        # 根据underline参数决定是否添加下划线
        text_decoration = ft.TextDecoration.UNDERLINE if underline else ft.TextDecoration.NONE
        
        return ft.Text(
            # 不设置value值，避免重复显示
            size=14,
            color=Colors["primary"],
            weight=ft.FontWeight.NORMAL,
            spans=[
                ft.TextSpan(
                    text,
                    ft.TextStyle(
                        color=Colors["primary"],
                        decoration=text_decoration
                    ),
                    url=url,
                    on_click=on_click
                )
            ]
        )


# 便捷函数
def center_text(text, size=30, color=None, **kwargs):
    """快速创建居中文本的便捷函数"""
    return Layout.center_text(text, size, color, **kwargs)


def right_text(text, size=30, color=None, **kwargs):
    """快速创建居右文本的便捷函数"""
    return Layout.right_text(text, size, color, **kwargs)


def left_text(text, size=30, color=None, **kwargs):
    """快速创建居左文本的便捷函数"""
    return Layout.left_text(text, size, color, **kwargs)


def aligned_text(text, size=16, color=None, align=ft.TextAlign.LEFT, **kwargs):
    """创建指定对齐方式的文本的便捷函数"""
    return Layout.create_text_block(text, size, color, align, **kwargs)


def heading(text, level=1, color=None):
    """快速创建标题文本的便捷函数"""
    return TextStyle.heading(text, level, color)


def caption(text, color=None):
    """快速创建说明文字的便捷函数"""
    return TextStyle.caption(text, color)


def body(text, size=14, color=None):
    """快速创建正文文本的便捷函数"""
    return TextStyle.body(text, size, color)


def link(text, url=None, on_click=None, underline=True):
    """快速创建链接文本的便捷函数"""
    return TextStyle.link(text, url, on_click, underline)
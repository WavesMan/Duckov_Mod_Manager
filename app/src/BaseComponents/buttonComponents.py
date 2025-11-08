# BaseComponents/buttonComponents.py
import flet as ft
from .themeManager import get_theme_colors


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
        ),
    )


def text_button(text, on_click=None):
    """
    创建文本按钮（无边框）
    
    Args:
        text (str): 按钮文本
        on_click (callable): 点击事件处理函数
        
    Returns:
        ft.TextButton: 配置好的文本按钮
    """
    colors = get_theme_colors()
    return ft.TextButton(
        text=text,
        on_click=on_click,
        style=ft.ButtonStyle(
            color=colors["primary"],
        ),
    )
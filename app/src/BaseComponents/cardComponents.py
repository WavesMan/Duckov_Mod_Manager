# BaseComponents/cardComponents.py
import flet as ft
from .themeManager import get_theme_colors


class Card:
    """卡片组件类，提供丰富的卡片功能"""
    
    @staticmethod
    def create(
        content,
        title=None,
        actions=None,
        expand=False,
        width=None,
        height=None,
        elevation=1,
        border_radius=8,
        padding=16,
        margin=8,
        bgcolor=None,
        outlined=False,
        image_src=None,
        image_src_base64=None,
        image_fit=ft.ImageFit.CONTAIN,
        image_repeat=ft.ImageRepeat.NO_REPEAT,
        shadow_color=None,
        animate=None,
        url=None,
        url_target=None,
        on_click=None,
        on_long_press=None,
        on_hover=None
    ):
        """
        创建一个功能完整的卡片
        
        Args:
            content: 卡片内容 (可以是字符串或Flet控件)
            title: 卡片标题 (可选)
            actions: 操作按钮列表 (可选)
            expand: 是否扩展填充
            width: 卡片宽度
            height: 卡片高度
            elevation: 阴影高度
            border_radius: 边框圆角
            padding: 内边距
            margin: 外边距
            bgcolor: 背景颜色
            outlined: 是否显示边框
            image_src: 背景图片URL
            image_src_base64: Base64编码的背景图片
            image_fit: 图片适应模式
            image_repeat: 图片重复模式
            shadow_color: 阴影颜色
            animate: 动画效果
            url: 点击卡片时跳转的链接
            url_target: 链接打开方式
            on_click: 点击事件处理函数
            on_long_press: 长按事件处理函数
            on_hover: 悬停事件处理函数
            
        Returns:
            ft.Card: 配置好的卡片组件
        """
        colors = get_theme_colors()
        
        # 如果没有指定背景色，使用主题色
        if bgcolor is None:
            bgcolor = colors["surface"]
            
        # 处理内容
        if isinstance(content, str):
            content = ft.Text(content)
            
        # 如果有标题或操作按钮，使用Column布局
        if title or actions:
            # 创建标题
            title_widget = None
            if title:
                if isinstance(title, str):
                    title_widget = ft.Text(title, size=20, weight=ft.FontWeight.BOLD, color=colors["text_primary"])
                else:
                    title_widget = title
                    
            # 创建操作按钮行
            actions_row = None
            if actions:
                actions_row = ft.Row(
                    actions,
                    alignment=ft.MainAxisAlignment.END,
                )
                
            # 组织内容
            content_col = ft.Column(
                controls=[control for control in [title_widget, content, actions_row] if control is not None],
                spacing=8,
                expand=True,
            )
            card_content = content_col
        else:
            card_content = content
            
        # 创建容器参数字典
        container_params = {
            "content": card_content,
            "padding": padding,
            "width": width,
            "height": height,
            "bgcolor": bgcolor,
            "border_radius": border_radius,
            "on_click": on_click,
            "on_long_press": on_long_press,
            "on_hover": on_hover,
            "url": url,
            "url_target": url_target,
            "animate": animate,
            "expand": expand,
        }
        
        # 如果需要边框，添加边框
        if outlined:
            container_params["border"] = ft.border.all(1, colors["text_secondary"])
            
        # 创建容器
        container = ft.Container(**container_params)
        
        # 创建卡片
        card = ft.Card(
            content=container,
            elevation=elevation,
            margin=margin,
            shadow_color=shadow_color,
            expand=expand,
        )
        
        return card


def simple_card(
    content,
    expand=False,
    width=None,
    height=None,
    elevation=1,
    padding=16,
    margin=8
):
    """
    创建一个简单的卡片
    
    Args:
        content: 卡片内容 (可以是字符串或Flet控件)
        expand: 是否扩展填充
        width: 卡片宽度
        height: 卡片高度
        elevation: 阴影高度
        padding: 内边距
        margin: 外边距
        
    Returns:
        ft.Card: 配置好的卡片组件
    """
    return Card.create(
        content=content,
        expand=expand,
        width=width,
        height=height,
        elevation=elevation,
        padding=padding,
        margin=margin
    )


def titled_card(
    title,
    content,
    actions=None,
    expand=False,
    width=None,
    height=None,
    elevation=1,
    padding=16,
    margin=8
):
    """
    创建一个带标题的卡片
    
    Args:
        title: 卡片标题 (可以是字符串或Flet控件)
        content: 卡片内容 (可以是字符串或Flet控件)
        actions: 操作按钮列表 (可选)
        expand: 是否扩展填充
        width: 卡片宽度
        height: 卡片高度
        elevation: 阴影高度
        padding: 内边距
        margin: 外边距
        
    Returns:
        ft.Card: 配置好的卡片组件
    """
    return Card.create(
        title=title,
        content=content,
        actions=actions,
        expand=expand,
        width=width,
        height=height,
        elevation=elevation,
        padding=padding,
        margin=margin
    )


def image_card(
    image_src,
    content=None,
    title=None,
    actions=None,
    image_height=150,
    expand=False,
    width=None,
    elevation=1,
    padding=16,
    margin=8,
    image_fit=ft.ImageFit.COVER
):
    """
    创建一个带图片的卡片
    
    Args:
        image_src: 图片URL
        content: 卡片内容 (可选)
        title: 卡片标题 (可选)
        actions: 操作按钮列表 (可选)
        image_height: 图片高度
        expand: 是否扩展填充
        width: 卡片宽度
        elevation: 阴影高度
        padding: 内边距
        margin: 外边距
        image_fit: 图片适应模式
        
    Returns:
        ft.Card: 配置好的卡片组件
    """
    # 创建图片控件
    image = ft.Image(
        src=image_src,
        height=image_height,
        fit=image_fit,
        width=width
    )
    
    # 组织内容
    if content or title or actions:
        # 如果有内容，创建一个包含图片和内容的列
        content_controls = [image]
        
        if title:
            if isinstance(title, str):
                colors = get_theme_colors()
                title = ft.Text(title, size=20, weight=ft.FontWeight.BOLD, color=colors["text_primary"])
            content_controls.append(title)
            
        if content:
            if isinstance(content, str):
                content = ft.Text(content)
            content_controls.append(content)
            
        if actions:
            actions_row = ft.Row(
                actions,
                alignment=ft.MainAxisAlignment.END,
            )
            content_controls.append(actions_row)
            
        card_content = ft.Column(
            content_controls,
            spacing=8
        )
    else:
        # 如果没有其他内容，只显示图片
        card_content = image
        
    return Card.create(
        content=card_content,
        expand=expand,
        width=width,
        elevation=elevation,
        padding=0,  # 图片卡片通常不需要内边距
        margin=margin
    )


def outlined_card(
    content,
    title=None,
    actions=None,
    expand=False,
    width=None,
    height=None,
    elevation=0,
    padding=16,
    margin=8
):
    """
    创建一个带边框的卡片（无阴影）
    
    Args:
        content: 卡片内容 (可以是字符串或Flet控件)
        title: 卡片标题 (可选)
        actions: 操作按钮列表 (可选)
        expand: 是否扩展填充
        width: 卡片宽度
        height: 卡片高度
        elevation: 阴影高度 (默认为0)
        padding: 内边距
        margin: 外边距
        
    Returns:
        ft.Card: 配置好的卡片组件
    """
    return Card.create(
        content=content,
        title=title,
        actions=actions,
        expand=expand,
        width=width,
        height=height,
        elevation=elevation,
        padding=padding,
        margin=margin,
        outlined=True
    )


def clickable_card(
    content,
    on_click,
    title=None,
    actions=None,
    expand=False,
    width=None,
    height=None,
    elevation=1,
    padding=16,
    margin=8
):
    """
    创建一个可点击的卡片
    
    Args:
        content: 卡片内容 (可以是字符串或Flet控件)
        on_click: 点击事件处理函数
        title: 卡片标题 (可选)
        actions: 操作按钮列表 (可选)
        expand: 是否扩展填充
        width: 卡片宽度
        height: 卡片高度
        elevation: 阴影高度
        padding: 内边距
        margin: 外边距
        
    Returns:
        ft.Card: 配置好的卡片组件
    """
    return Card.create(
        content=content,
        title=title,
        actions=actions,
        expand=expand,
        width=width,
        height=height,
        elevation=elevation,
        padding=padding,
        margin=margin,
        on_click=on_click
    )
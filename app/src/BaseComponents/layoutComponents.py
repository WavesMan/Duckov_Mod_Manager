# BaseComponents/layoutComponents.py
import flet as ft


class ScrollablePage:
    """可滚动页面布局组件"""
    
    @staticmethod
    def create(
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
        创建一个可滚动的页面布局
        
        Args:
            content: 页面内容（可以是控件列表或单个控件）
            scroll: 滚动模式 (ft.ScrollMode.AUTO, ft.ScrollMode.ALWAYS, ft.ScrollMode.NONE等)
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
    return ScrollablePage.create(
        content=content,
        scroll=scroll,
        alignment=alignment,
        horizontal_alignment=horizontal_alignment,
        spacing=spacing,
        padding=padding,
        auto_scroll=auto_scroll,
        **kwargs
    )


class ResponsiveLayout:
    """响应式布局组件"""
    
    @staticmethod
    def create(
        content,
        width=None,
        height=None,
        expand=True,
        alignment=ft.alignment.top_left,
        **kwargs
    ):
        """
        创建一个响应式布局容器
        
        Args:
            content: 容器内容
            width: 容器宽度
            height: 容器高度
            expand: 是否扩展填充
            alignment: 对齐方式
            **kwargs: 其他参数
            
        Returns:
            ft.Container: 配置好的容器
        """
        container = ft.Container(
            content=content,
            width=width,
            height=height,
            expand=expand,
            alignment=alignment,
            **kwargs
        )
        
        return container


def responsive_layout(
    content,
    width=None,
    height=None,
    expand=True,
    alignment=ft.alignment.top_left,
    **kwargs
):
    """
    创建一个响应式布局容器的便捷函数
    
    Args:
        content: 容器内容
        width: 容器宽度
        height: 容器高度
        expand: 是否扩展填充
        alignment: 对齐方式
        **kwargs: 其他参数
        
    Returns:
        ft.Container: 配置好的容器
    """
    return ResponsiveLayout.create(
        content=content,
        width=width,
        height=height,
        expand=expand,
        alignment=alignment,
        **kwargs
    )
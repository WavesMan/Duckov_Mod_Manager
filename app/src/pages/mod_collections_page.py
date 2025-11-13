# pages/mod_collections_page.py
import flet as ft
import sys
import os

# 添加src目录到Python路径
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from services.theme_manager import get_theme_colors, create_card
from services.mod_manager import mod_manager
from services.mod_collection_manager import collection_manager


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


def mod_collections_page_view(page: ft.Page):
    """Mod合集管理页面视图"""
    colors = get_theme_colors()
    
    # 创建合集列表容器
    collections_list_container = ft.Column(spacing=10)
    
    # 创建合集详情容器
    collection_details_container = ft.Column(spacing=10, visible=False)
    
    # 当前选中的合集ID
    current_collection_id = None
    
    # 刷新合集列表
    def refresh_collections_list():
        collections = collection_manager.get_collections()
        collections_list_container.controls.clear()
        
        if not collections:
            # 显示空状态
            empty_state = ft.Column([
                ft.Icon(ft.Icons.FOLDER_OFF, size=64, color=colors["text_secondary"]),
                heading("暂无合集", level=3),
                body("创建您的第一个Mod合集来更好地管理模组"),
                primary_button("创建合集", on_click=lambda _: show_create_collection_dialog()),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=20)
            collections_list_container.controls.append(empty_state)
        else:
            # 显示合集列表
            for collection in collections:
                collection_card = create_collection_card(collection)
                collections_list_container.controls.append(collection_card)
        
        page.update()
    
    # 创建合集卡片
    def create_collection_card(collection):
        def on_edit_click(e):
            show_edit_collection_dialog(collection['id'], collection['name'])
        
        def on_delete_click(e):
            show_delete_confirmation_dialog(collection['id'], collection['name'])
        
        def on_select_click(e):
            show_collection_details(collection['id'])
        
        card_content = ft.Column([
            ft.Row([
                heading(collection['name'], level=3),
                ft.Row([
                    ft.IconButton(
                        icon=ft.Icons.EDIT,
                        tooltip="编辑合集",
                        on_click=on_edit_click
                    ),
                    ft.IconButton(
                        icon=ft.Icons.DELETE,
                        tooltip="删除合集",
                        on_click=on_delete_click
                    ),
                ], spacing=0)
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
            ft.Row([
                caption(f"{len(collection.get('mods', []))} 个模组"),
                primary_button("查看", on_click=on_select_click)
            ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
        ], spacing=10)
        
        return create_card(card_content, padding=15)
    
    # 显示创建合集对话框
    def show_create_collection_dialog():
        def close_dialog(e):
            dialog.open = False
            page.update()
        
        def create_collection(e):
            name = name_field.value.strip()
            if name:
                collection_manager.create_collection(name)
                refresh_collections_list()
                close_dialog(e)
        
        name_field = ft.TextField(
            label="合集名称",
            width=300,
            label_style=ft.TextStyle(color=colors["text_primary"]),
            border_color="#999999"
        )
        
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("创建新合集", level=3),
            content=ft.Column([
                body("为您的新合集输入一个名称"),
                name_field
            ], spacing=20, width=350),
            actions=[
                secondary_button("取消", on_click=close_dialog),
                primary_button("创建", on_click=create_collection),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        page.dialog = dialog
        dialog.open = True
        page.update()
        
        # 自动聚焦到输入框
        name_field.focus()
    
    # 显示编辑合集对话框
    def show_edit_collection_dialog(collection_id, current_name):
        def close_dialog(e):
            dialog.open = False
            page.update()
        
        def update_collection(e):
            new_name = name_field.value.strip()
            if new_name and new_name != current_name:
                collection_manager.update_collection_name(collection_id, new_name)
                refresh_collections_list()
                close_dialog(e)
            elif not new_name:
                # 显示错误提示
                name_field.error_text = "合集名称不能为空"
                page.update()
        
        name_field = ft.TextField(
            label="合集名称",
            value=current_name,
            width=300,
            label_style=ft.TextStyle(color=colors["text_primary"]),
            border_color="#999999"
        )
        
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("编辑合集", level=3),
            content=ft.Column([
                body("修改合集名称"),
                name_field
            ], spacing=20, width=350),
            actions=[
                secondary_button("取消", on_click=close_dialog),
                primary_button("保存", on_click=update_collection),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        page.dialog = dialog
        dialog.open = True
        page.update()
        
        # 自动聚焦到输入框
        name_field.focus()
    
    # 显示删除确认对话框
    def show_delete_confirmation_dialog(collection_id, collection_name):
        def close_dialog(e):
            dialog.open = False
            page.update()
        
        def delete_collection(e):
            collection_manager.delete_collection(collection_id)
            refresh_collections_list()
            # 如果当前显示的是被删除的合集，隐藏详情
            if current_collection_id == collection_id:
                hide_collection_details()
            close_dialog(e)
        
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("确认删除", level=3),
            content=body(f"确定要删除合集 '{collection_name}' 吗？此操作不可恢复。"),
            actions=[
                secondary_button("取消", on_click=close_dialog),
                ft.ElevatedButton(
                    text="删除",
                    on_click=delete_collection,
                    style=ft.ButtonStyle(
                        color=ft.Colors.WHITE,
                        bgcolor=colors["error"],
                        text_style=ft.TextStyle(font_family="MiSans")
                    ),
                ),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        page.dialog = dialog
        dialog.open = True
        page.update()
    
    # 显示合集详情
    def show_collection_details(collection_id):
        nonlocal current_collection_id
        current_collection_id = collection_id
        
        collection = collection_manager.get_collection_by_id(collection_id)
        if not collection:
            return
        
        # 显示详情容器
        collection_details_container.visible = True
        
        # 更新详情内容
        update_collection_details(collection)
        
        # 滚动到详情部分
        page.scroll_to(key="collection_details")
        
        page.update()
    
    # 隐藏合集详情
    def hide_collection_details():
        nonlocal current_collection_id
        current_collection_id = None
        collection_details_container.visible = False
        page.update()
    
    # 更新合集详情内容
    def update_collection_details(collection):
        collection_details_container.controls.clear()
        
        # 返回按钮
        back_button = ft.IconButton(
            icon=ft.Icons.ARROW_BACK,
            tooltip="返回合集列表",
            on_click=lambda _: hide_collection_details()
        )
        
        # 合集标题行
        title_row = ft.Row([
            back_button,
            heading(collection['name'], level=2),
            ft.Row([
                primary_button("启用合集", on_click=lambda _: enable_collection(collection['id'])),
                secondary_button("禁用合集", on_click=lambda _: disable_collection(collection['id'])),
            ])
        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
        
        # 操作按钮行
        actions_row = ft.Row([
            primary_button("添加模组", on_click=lambda _: show_add_mods_dialog(collection['id'])),
            secondary_button("编辑顺序", on_click=lambda _: show_edit_order_dialog(collection['id'])),
        ], spacing=10)
        
        # 模组列表
        mods_list_container = ft.Column(spacing=10)
        refresh_collection_mods_list(collection['id'], mods_list_container)
        
        collection_details_container.controls.extend([
            title_row,
            ft.Divider(),
            actions_row,
            ft.Divider(),
            heading("模组列表", level=3),
            mods_list_container
        ])
    
    # 刷新合集模组列表
    def refresh_collection_mods_list(collection_id, container):
        mods = collection_manager.get_collection_mods(collection_id)
        container.controls.clear()
        
        if not mods:
            empty_state = ft.Column([
                ft.Icon(ft.Icons.INBOX, size=48, color=colors["text_secondary"]),
                body("此合集中还没有模组"),
                body("点击上方'添加模组'按钮来添加模组"),
            ], horizontal_alignment=ft.CrossAxisAlignment.CENTER, spacing=10)
            container.controls.append(empty_state)
        else:
            # 显示模组列表（简化版，无图片和描述）
            for mod in mods:
                mod_item = create_simple_mod_item(mod, collection_id)
                container.controls.append(mod_item)
    
    # 创建简化版模组项
    def create_simple_mod_item(mod_info, collection_id):
        def on_remove_click(e):
            # 确认删除对话框
            def close_dialog(e):
                dialog.open = False
                page.update()
            
            def remove_mod(e):
                collection_manager.remove_mods_from_collection(collection_id, [str(mod_info['id'])])
                # 刷新当前合集详情
                collection = collection_manager.get_collection_by_id(collection_id)
                if collection:
                    update_collection_details(collection)
                close_dialog(e)
            
            dialog = ft.AlertDialog(
                modal=True,
                title=heading("确认移除", level=3),
                content=body(f"确定要从合集中移除模组 '{mod_info.get('display_name', mod_info.get('name', f'模组 {mod_info['id']}'))}' 吗？"),
                actions=[
                    secondary_button("取消", on_click=close_dialog),
                    ft.ElevatedButton(
                        text="移除",
                        on_click=remove_mod,
                        style=ft.ButtonStyle(
                            color=ft.Colors.WHITE,
                            bgcolor=colors["error"],
                            text_style=ft.TextStyle(font_family="MiSans")
                        ),
                    ),
                ],
                actions_alignment=ft.MainAxisAlignment.END,
            )
            
            page.dialog = dialog
            dialog.open = True
            page.update()
        
        mod_name = mod_info.get('display_name', mod_info.get('name', f'模组 {mod_info["id"]}'))
        mod_status = "已启用" if mod_manager.is_mod_enabled(mod_info['id']) else "已禁用"
        status_color = colors["primary"] if mod_manager.is_mod_enabled(mod_info['id']) else colors["text_secondary"]
        
        item = ft.Row([
            ft.Column([
                body(mod_name, weight=ft.FontWeight.BOLD),
                caption(mod_status, color=status_color)
            ], expand=True),
            ft.IconButton(
                icon=ft.Icons.DELETE,
                tooltip="从合集中移除",
                on_click=on_remove_click
            )
        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN)
        
        return create_card(item, padding=10)
    
    # 显示添加模组对话框
    def show_add_mods_dialog(collection_id):
        # 获取所有已下载的模组
        all_mods = mod_manager.get_downloaded_mods()
        
        # 过滤掉已经在合集中的模组
        collection = collection_manager.get_collection_by_id(collection_id)
        if collection:
            existing_mods = set(collection.get('mods', []))
            available_mods = [mod for mod in all_mods if mod['id'] not in existing_mods]
        else:
            available_mods = all_mods
        
        if not available_mods:
            # 显示提示对话框
            dialog = ft.AlertDialog(
                modal=True,
                title=heading("提示", level=3),
                content=body("没有可用的模组可以添加到此合集"),
                actions=[
                    primary_button("确定", on_click=lambda e: close_simple_dialog(dialog)),
                ],
                actions_alignment=ft.MainAxisAlignment.END,
            )
            
            page.dialog = dialog
            dialog.open = True
            page.update()
            return
        
        # 创建模组选择列表
        selected_mods = set()
        
        def on_mod_select(mod_id, checkbox):
            if checkbox.value:
                selected_mods.add(mod_id)
            else:
                selected_mods.discard(mod_id)
        
        mod_list_container = ft.Column(spacing=10, scroll=ft.ScrollMode.AUTO, height=300)
        
        # 创建模组项
        for mod in available_mods:
            mod_id = mod['id']
            mod_name = mod.get('display_name', mod.get('name', f'模组 {mod_id}'))
            
            checkbox = ft.Checkbox(
                label=mod_name,
                on_change=lambda e, mid=mod_id, cb=None: on_mod_select(mid, cb or e.control)
            )
            # 修正闭包问题
            checkbox.on_change = lambda e, mid=mod_id, cb=checkbox: on_mod_select(mid, cb)
            
            mod_item = ft.Container(
                content=checkbox,
                padding=ft.Padding(10, 5, 10, 5)
            )
            mod_list_container.controls.append(mod_item)
        
        def close_dialog(e):
            dialog.open = False
            page.update()
        
        def add_selected_mods(e):
            if selected_mods:
                collection_manager.add_mods_to_collection(collection_id, list(selected_mods))
                # 刷新当前合集详情
                collection = collection_manager.get_collection_by_id(collection_id)
                if collection:
                    update_collection_details(collection)
                close_dialog(e)
            else:
                # 显示提示
                page.snack_bar = ft.SnackBar(
                    content=ft.Text("请选择至少一个模组"),
                    bgcolor=colors["warning"],
                )
                page.snack_bar.open = True
                page.update()
        
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("添加模组到合集", level=3),
            content=ft.Column([
                body("选择要添加到合集的模组："),
                mod_list_container
            ], spacing=20, width=400),
            actions=[
                secondary_button("取消", on_click=close_dialog),
                primary_button("添加", on_click=add_selected_mods),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        page.dialog = dialog
        dialog.open = True
        page.update()
    
    # 显示编辑顺序对话框
    def show_edit_order_dialog(collection_id):
        collection = collection_manager.get_collection_by_id(collection_id)
        if not collection:
            return
        
        mods = collection_manager.get_collection_mods(collection_id)
        if not mods:
            # 显示提示对话框
            dialog = ft.AlertDialog(
                modal=True,
                title=heading("提示", level=3),
                content=body("合集中没有模组可以排序"),
                actions=[
                    primary_button("确定", on_click=lambda e: close_simple_dialog(dialog)),
                ],
                actions_alignment=ft.MainAxisAlignment.END,
            )
            
            page.dialog = dialog
            dialog.open = True
            page.update()
            return
        
        # 创建可拖拽的模组列表
        mod_items = []
        
        def create_draggable_item(mod_info, index):
            mod_name = mod_info.get('display_name', mod_info.get('name', f'模组 {mod_info["id"]}'))
            
            # 拖拽目标区域
            drag_target = ft.DragTarget(
                group="mods",
                content=ft.Container(
                    content=ft.Row([
                        ft.Icon(ft.Icons.DRAG_INDICATOR, color=colors["text_secondary"]),
                        body(mod_name, weight=ft.FontWeight.BOLD),
                        ft.IconButton(
                            icon=ft.Icons.DELETE,
                            icon_size=18,
                            tooltip="从合集中移除",
                            on_click=lambda e, mid=mod_info['id']: remove_mod_from_order_dialog(collection_id, mid, mod_name, refresh_order_list)
                        )
                    ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
                    padding=10,
                    border_radius=5,
                    bgcolor=colors["surface"],
                ),
                on_accept=lambda e, idx=index: move_item(e, idx),
            )
            
            # 拖拽源
            draggable = ft.Draggable(
                group="mods",
                content=drag_target,
                data=index,
            )
            
            mod_items.append({
                'draggable': draggable,
                'mod_info': mod_info,
                'index': index
            })
            
            return draggable
        
        def move_item(e, target_index):
            # 获取拖拽的数据（源索引）
            source_index = e.src_data
            if source_index != target_index:
                # 重新排列模组项
                item = mod_items.pop(source_index)
                mod_items.insert(target_index, item)
                
                # 更新索引
                for i, item_data in enumerate(mod_items):
                    item_data['index'] = i
                    # 更新draggable的data属性
                    item_data['draggable'].data = i
                
                # 更新显示
                refresh_order_list()
        
        def refresh_order_list():
            order_list_container.controls.clear()
            for i, mod_data in enumerate(mods):
                draggable_item = create_draggable_item(mod_data, i)
                order_list_container.controls.append(draggable_item)
            page.update()
        
        def remove_mod_from_order_dialog(collection_id, mod_id, mod_name, refresh_callback):
            def close_dialog(e):
                dialog.open = False
                page.update()
            
            def remove_mod(e):
                collection_manager.remove_mods_from_collection(collection_id, [mod_id])
                # 更新本地mods列表
                nonlocal mods
                mods = [mod for mod in mods if mod['id'] != mod_id]
                refresh_callback()
                close_dialog(e)
            
            dialog = ft.AlertDialog(
                modal=True,
                title=heading("确认移除", level=3),
                content=body(f"确定要从合集中移除模组 '{mod_name}' 吗？"),
                actions=[
                    secondary_button("取消", on_click=close_dialog),
                    ft.ElevatedButton(
                        text="移除",
                        on_click=remove_mod,
                        style=ft.ButtonStyle(
                            color=ft.Colors.WHITE,
                            bgcolor=colors["error"],
                            text_style=ft.TextStyle(font_family="MiSans")
                        ),
                    ),
                ],
                actions_alignment=ft.MainAxisAlignment.END,
            )
            
            page.dialog = dialog
            dialog.open = True
            page.update()
        
        order_list_container = ft.Column(spacing=5)
        
        # 初始化列表
        for i, mod in enumerate(mods):
            draggable_item = create_draggable_item(mod, i)
            order_list_container.controls.append(draggable_item)
        
        def close_dialog(e):
            dialog.open = False
            page.update()
        
        def save_order(e):
            # 根据当前顺序保存模组顺序
            new_order = [item['mod_info']['id'] for item in mod_items]
            collection_manager.update_mods_order(collection_id, new_order)
            
            # 刷新当前合集详情
            updated_collection = collection_manager.get_collection_by_id(collection_id)
            if updated_collection:
                update_collection_details(updated_collection)
            
            close_dialog(e)
        
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("编辑模组顺序", level=3),
            content=ft.Column([
                body("拖拽模组来调整它们的显示顺序："),
                order_list_container
            ], spacing=20, width=400, height=400),
            actions=[
                secondary_button("取消", on_click=close_dialog),
                primary_button("保存顺序", on_click=save_order),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        page.dialog = dialog
        dialog.open = True
        page.update()
    
    # 简单对话框关闭函数
    def close_simple_dialog(dialog):
        dialog.open = False
        page.update()
    
    # 启用合集
    def enable_collection(collection_id):
        def close_dialog(e):
            dialog.open = False
            page.update()
        
        def confirm_enable(e):
            success = collection_manager.enable_collection(collection_id)
            close_dialog(e)
            
            if success:
                page.snack_bar = ft.SnackBar(
                    content=ft.Text("合集启用成功"),
                    bgcolor=ft.Colors.GREEN,
                )
                # 刷新当前合集详情
                collection = collection_manager.get_collection_by_id(collection_id)
                if collection:
                    update_collection_details(collection)
            else:
                page.snack_bar = ft.SnackBar(
                    content=ft.Text("合集启用失败，请查看日志"),
                    bgcolor=colors["error"],
                )
            page.snack_bar.open = True
            page.update()
        
        # 显示确认对话框
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("确认启用", level=3),
            content=body("启用此合集将禁用所有其他合集中的模组。确定要继续吗？"),
            actions=[
                secondary_button("取消", on_click=close_dialog),
                primary_button("确认启用", on_click=confirm_enable),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        page.dialog = dialog
        dialog.open = True
        page.update()
    
    # 禁用合集
    def disable_collection(collection_id):
        def close_dialog(e):
            dialog.open = False
            page.update()
        
        def confirm_disable(e):
            success = collection_manager.disable_collection(collection_id)
            close_dialog(e)
            
            if success:
                page.snack_bar = ft.SnackBar(
                    content=ft.Text("合集禁用成功"),
                    bgcolor=ft.Colors.GREEN,
                )
                # 刷新当前合集详情
                collection = collection_manager.get_collection_by_id(collection_id)
                if collection:
                    update_collection_details(collection)
            else:
                page.snack_bar = ft.SnackBar(
                    content=ft.Text("合集禁用失败，请查看日志"),
                    bgcolor=colors["error"],
                )
            page.snack_bar.open = True
            page.update()
        
        # 显示确认对话框
        dialog = ft.AlertDialog(
            modal=True,
            title=heading("确认禁用", level=3),
            content=body("确定要禁用此合集中的所有模组吗？"),
            actions=[
                secondary_button("取消", on_click=close_dialog),
                ft.ElevatedButton(
                    text="确认禁用",
                    on_click=confirm_disable,
                    style=ft.ButtonStyle(
                        color=ft.Colors.WHITE,
                        bgcolor=colors["error"],
                        text_style=ft.TextStyle(font_family="MiSans")
                    ),
                ),
            ],
            actions_alignment=ft.MainAxisAlignment.END,
        )
        
        page.dialog = dialog
        dialog.open = True
        page.update()
    
    # 页面内容
    page_content = ft.Column([
        ft.Row([
            heading("Mod合集", level=1),
            primary_button("创建合集", on_click=lambda _: show_create_collection_dialog()),
        ], alignment=ft.MainAxisAlignment.SPACE_BETWEEN),
        body("创建和管理您的Mod合集，更好地组织和控制模组。"),
        ft.Divider(height=20),
        
        # 合集列表部分
        ft.Column([
            heading("我的合集", level=2),
            collections_list_container
        ], spacing=10),
        
        ft.Divider(height=20),
        
        # 合集详情部分
        ft.Column([
            collection_details_container
        ], spacing=10, key="collection_details")
    ], spacing=10)
    
    # 首次加载时刷新合集列表
    refresh_collections_list()
    
    return page_content
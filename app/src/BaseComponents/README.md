# BaseComponents 基础组件库

BaseComponents 是一个为 Flet 应用程序设计的可复用组件库，提供了一套统一的 UI 组件和主题管理系统，帮助开发者快速构建具有一致外观和用户体验的应用程序。

## 目录结构

```
BaseComponents/
├── __init__.py          # 导出所有组件
├── textComponents.py    # 文本相关组件
├── buttonComponents.py  # 按钮相关组件
├── inputComponents.py   # 输入相关组件
├── cardComponents.py    # 卡片相关组件
├── layoutComponents.py  # 布局相关组件
├── appLayout.py         # 应用程序布局组件
└── themeManager.py      # 主题管理器
```

## 组件介绍

### 文本组件 (textComponents.py)

提供多种文本样式和布局组件：

- `center_text(text, size=30, color=None, **kwargs)` - 创建居中文本
- `right_text(text, size=30, color=None, **kwargs)` - 创建居右文本
- `left_text(text, size=30, color=None, **kwargs)` - 创建居左文本
- `aligned_text(text, size=16, color=None, align=ft.TextAlign.LEFT, **kwargs)` - 创建指定对齐方式的文本
- `heading(text, level=1, color=None)` - 创建标题文本 (level 1-6)
- `body(text, size=14, color=None)` - 创建正文文本
- `caption(text, color=None)` - 创建说明文字
- `link(text, url=None, on_click=None, underline=True)` - 创建链接文本

示例：
```python
from BaseComponents import *

# 创建不同类型的文本
page.add(
    heading("主标题", level=1),
    body("这是一段正文内容"),
    caption("这是一段说明文字"),
    link("带下划线的链接", url="https://example.com"),
    link("不带下划线的链接", url="https://example.com", underline=False),
    aligned_text("居中文本", size=20, align=ft.TextAlign.CENTER),
    aligned_text("居右文本", size=20, align=ft.TextAlign.RIGHT)
)
```

### 按钮组件 (buttonComponents.py)

提供多种样式的按钮组件：

- `primary_button(text, on_click=None, width=None, height=None)` - 主要按钮
- `secondary_button(text, on_click=None, width=None, height=None)` - 次要按钮
- `icon_button(icon, on_click=None, tooltip=None)` - 图标按钮

示例：
```python
from BaseComponents import *

def button_clicked(e):
    print("按钮被点击了")

page.add(
    primary_button("主要操作", on_click=button_clicked),
    secondary_button("次要操作", on_click=button_clicked),
    icon_button(icons.ADD, on_click=button_clicked, tooltip="添加")
)
```

### 输入组件 (inputComponents.py)

提供常用的输入控件：

- `text_field(label, hint_text=None, on_change=None, width=None)` - 文本输入框
- `dropdown(label, options, on_change=None, width=None)` - 下拉选择框
- `checkbox(label, value=False, on_change=None)` - 复选框

示例：
```python
from BaseComponents import *

def on_text_change(e):
    print(f"文本改变: {e.control.value}")

def on_dropdown_change(e):
    print(f"选择改变: {e.control.value}")

page.add(
    text_field("用户名", hint_text="请输入用户名", on_change=on_text_change),
    dropdown("选择项", ["选项1", "选项2", "选项3"], on_change=on_dropdown_change),
    checkbox("同意条款")
)
```

### 卡片组件 (cardComponents.py)

提供功能丰富的卡片组件，支持标题、操作按钮、图片、点击事件等：

- `Card.create(...)` - 创建自定义卡片（完整功能）
- `simple_card(content, ...)` - 创建简单卡片
- `titled_card(title, content, actions=None, ...)` - 创建带标题的卡片
- `image_card(image_src, content=None, ...)` - 创建带图片的卡片
- `outlined_card(content, ...)` - 创建带边框的卡片
- `clickable_card(content, on_click, ...)` - 创建可点击的卡片

示例：
```python
from BaseComponents import *

# 简单卡片
page.add(
    simple_card("这是一个简单的卡片")
)

# 带标题的卡片
page.add(
    titled_card(
        title="卡片标题",
        content="这是卡片的内容",
        actions=[
            primary_button("确定"),
            secondary_button("取消")
        ]
    )
)

# 带图片的卡片
page.add(
    image_card(
        image_src="https://picsum.photos/300/200",
        title="图片标题",
        content="这是图片卡片的内容"
    )
)

# 可点击的卡片
def card_clicked(e):
    print("卡片被点击了")

page.add(
    clickable_card(
        content="点击我",
        on_click=card_clicked
    )
)
```

### 布局组件 (layoutComponents.py)

提供页面布局和响应式设计组件：

- `ScrollablePage.create(...)` - 创建可滚动页面布局
- `scrollable_page(content, ...)` - 创建可滚动页面布局的便捷函数
- `ResponsiveLayout.create(...)` - 创建响应式布局容器
- `responsive_layout(content, ...)` - 创建响应式布局容器的便捷函数

示例：
```python
from BaseComponents import *

# 创建可滚动页面，可以控制对齐方式
demo_content = [
    heading("页面标题"),
    body("页面内容..."),
    # 更多内容...
]

# 左对齐（默认）
scrollable_content = scrollable_page(
    content=demo_content,
    horizontal_alignment=ft.CrossAxisAlignment.START
)

# 居中对齐
scrollable_content_center = scrollable_page(
    content=demo_content,
    horizontal_alignment=ft.CrossAxisAlignment.CENTER
)

# 右对齐
scrollable_content_right = scrollable_page(
    content=demo_content,
    horizontal_alignment=ft.CrossAxisAlignment.END
)

page.add(scrollable_content)

# 创建响应式布局
responsive_content = responsive_layout(
    content=ft.Text("响应式内容"),
    width=400,
    height=300
)
page.add(responsive_content)
```

### 应用程序布局组件 (appLayout.py)

提供现代化的应用程序布局，包括可折叠侧边栏、顶部导航栏和主内容区：

- `AppLayout` - 主应用程序布局类
- `NavigationItem` - 侧边栏导航项数据类
- `create_app_layout(page, title)` - 创建应用程序布局的便捷函数

示例：
```python
from BaseComponents import *

def main(page: ft.Page):
    # 创建应用程序布局
    app_layout = create_app_layout(page, "我的应用")
    
    # 设置主内容
    app_layout.set_content(ft.Text("主内容区域"))
    
    # 添加导航项
    nav_item = {
        "text": "主页",
        "icon": ft.icons.HOME,
        "route": "/home",
        "on_click": lambda e: print("导航到主页")
    }
    app_layout.add_sidebar_item(nav_item)

ft.app(main)
```

## 主题系统 (themeManager.py)

提供统一的主题色管理和自动适配功能。

### 主题颜色

预定义的颜色常量：
- PRIMARY - 主色
- SECONDARY - 辅助色
- SUCCESS - 成功色
- WARNING - 警告色
- ERROR - 错误色
- BACKGROUND - 背景色
- SURFACE - 表面色
- TEXT_PRIMARY - 主要文本色
- TEXT_SECONDARY - 次要文本色

### 主题功能

- `get_theme_colors()` - 获取当前主题颜色配置
- `switch_theme(theme)` - 切换主题 ("light" 或 "dark")
- `auto_detect_theme()` - 自动检测系统主题
- `themed_button(text, on_click=None, button_type="primary")` - 主题化按钮
- `themed_text(text, text_type="body")` - 主题化文本
- `themed_container(content, container_type="card")` - 主题化容器

示例：
```python
from BaseComponents import *

# 自动检测系统主题
auto_detect_theme()

# 手动切换主题
switch_theme("dark")  # 或 "light"

# 使用主题化组件
page.add(
    themed_button("主题按钮", button_type="success"),
    themed_text("主题文本", text_type="heading"),
    themed_container(content)
)
```

## 使用方法

1. 导入组件：
```python
from BaseComponents import *
```

2. 在页面中使用组件：
```python
def main(page: ft.Page):
    # 设置窗口大小
    page.window_width = 800
    page.window_height = 600
    page.window_resizable = True
    
    # 启用页面滚动
    page.scroll = ft.ScrollMode.AUTO
    
    page.add(
        heading("欢迎使用 BaseComponents"),
        body("这是一个示例应用"),
        primary_button("点击我", on_click=lambda e: print("点击事件"))
    )

ft.app(main)
```

## 主题自动适配

BaseComponents 支持自动检测用户系统的主题设置（深色或浅色模式），并相应地应用主题。这通过 `darkdetect` 库实现，需要额外安装：

```bash
pip install darkdetect
```

在应用启动时，主题管理器会自动检测系统主题并应用相应的颜色方案。

## 自定义主题

可以通过修改 [themeManager.py](file:///D:/GitHub/Source_Codes2/Duckov_Mod_Manager/app/src/BaseComponents/themeManager.py) 中的 [AppColors](file:///D:/GitHub/Source_Codes2/Duckov_Mod_Manager/app/src/BaseComponents/themeManager.py#L5-L43) 类来自定义颜色方案，或者通过 `switch_theme()` 函数在运行时切换主题。

## 窗口大小和滚动功能

BaseComponents 现在支持窗口大小控制和内容滚动功能：

1. 设置窗口大小：
```python
page.window_width = 800
page.window_height = 600
page.window_resizable = True
```

2. 启用页面滚动：
```python
page.scroll = ft.ScrollMode.AUTO
```

3. 使用可滚动布局组件：
```python
content = [/* 你的页面内容 */]
# 左对齐（默认）
scrollable_content = scrollable_page(
    content=content,
    horizontal_alignment=ft.CrossAxisAlignment.START
)
page.add(scrollable_content)
```

当页面内容超出窗口大小时，用户可以滚动查看所有内容。通过对齐参数可以控制内容的对齐方式：
- `ft.CrossAxisAlignment.START` - 左对齐
- `ft.CrossAxisAlignment.CENTER` - 居中对齐
- `ft.CrossAxisAlignment.END` - 右对齐

## 独立文本对齐控制

现在可以通过 [aligned_text](file://D:\GitHub\Source_Codes2\Duckov_Mod_Manager\app\src\BaseComponents\textComponents.py#L270-L274) 函数为每个文本组件独立设置对齐方式，而不依赖于全局布局设置：

```python
# 创建具有不同对齐方式的文本
demo_content = [
    aligned_text("居中文本", size=30, align=ft.TextAlign.CENTER),
    aligned_text("居左文本", size=30, align=ft.TextAlign.LEFT),
    aligned_text("居右文本", size=30, align=ft.TextAlign.RIGHT),
    aligned_text("两端对齐文本", size=30, align=ft.TextAlign.JUSTIFY)
]
```

这种方式允许你在同一个页面中混合使用不同对齐方式的文本，提供了更大的灵活性。
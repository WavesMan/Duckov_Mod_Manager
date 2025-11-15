# Duckov Mod 开发实施方案与技术标准

版本：v1.0.0  日期：2025-11-14

## 版本记录
- v0.9.0：初版开发方式与标准草案
- v1.0.0：定稿，补全测试与部署章节、FAQ 与代码示例

## 目录
- 概览
- 开发方式确认
- 开发标准制定
- 必要文件清单
- 依赖包管理
- 开发环境配置指南
- 项目结构说明
- API 调用示例
- 常见问题解决方案
- 测试验证方法
- 部署发布流程
- 参考索引

## 概览
- Mod 通过 `Application.dataPath/Mods` 目录被发现与管理（duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:170-176）。
- 每个 Mod 以文件夹为单位，包含 `info.ini`、可选 `preview.png` 与 `<name>.dll`，其中类型命名需为 `<name>.ModBehaviour` 并继承核心 `ModBehaviour`（ModInfo.cs:7-13；ModManager.cs:430-447）。
- 加载与生命周期由 `ModManager` 驱动，关键事件包括扫描、激活、停用前通知与状态变更（ModManager.cs:191-208）。

## 开发方式确认
- API 与技术规范
  - `ModBehaviour` 基类提供生命周期钩子与上下文：
    - `Setup(ModManager master, ModInfo info)` 设置上下文并触发 `OnAfterSetup`（ModBehaviour.cs:20-25）。
    - `NotifyBeforeDeactivate()` 触发 `OnBeforeDeactivate`（ModBehaviour.cs:28-31）。
    - 钩子：`protected virtual void OnAfterSetup()`、`protected virtual void OnBeforeDeactivate()`（ModBehaviour.cs:34-41）。
  - `ModManager` 方法与事件：
    - 扫描：`Rescan()`（ModManager.cs:209-230）。
    - 批量激活：`ScanAndActivateMods()`（ModManager.cs:54-73）。
    - 单项激活/停用：`ActivateMod(info)`、`DeactivateMod(info)`（ModManager.cs:417-495, 379-414）。
    - 状态查询：`IsModActive(info, out instance)`（ModManager.cs:361-365）。
    - 事件：`OnScan`、`OnModActivated`、`OnModWillBeDeactivated`、`OnModStatusChanged`、`OnReorder`、`OnModLoadingFailed`（ModManager.cs:18, 191-208, 522）。
  - Trigger/Effect 机制：统一入口 `EffectTrigger.Trigger(...)` 驱动 `Effect.Trigger(...)` 完成过滤与动作（ItemStatsSystem/EffectTrigger.cs:33-36；Effect.cs:117-135）。
- 代码架构与模块划分
  - Modding：`ModManager`、`ModInfo`、`ModBehaviour` 及 UI（ModManagerUI、ModEntry）。
  - ItemStatsSystem：物品效果管线（Effect、Trigger、Filter、Action）。
  - 输入与 UI：`InputManager`、`UIInputManager` 等分布式事件入口。
- Hook 点与扩展机制
  - 生命周期：重写 `OnAfterSetup` 与 `OnBeforeDeactivate`。
  - 事件订阅：按需订阅 `ModManager.*` 或其他 `On*` 事件（例如 `Health.OnHurt`、`InputManager.OnSwitchWeaponInput`）。
  - 触发链路：基于 `EffectTrigger` 的触发-过滤-动作三段式。

## 开发标准制定
- 代码风格规范
  - 缩进：4 空格；换行 `LF`；UTF-8 编码。
  - 命名：
    - 命名空间：与 `info.ini` 的 `name` 一致，示例 `MyAwesomeMod`。
    - 类：`PascalCase`；方法 `PascalCase`；字段 `camelCase`；常量 `UPPER_CASE`。
    - 必须类：`<name>.ModBehaviour`。
  - 文件组织：按功能归档于 `src/`，保持单一职责。
- 模块接口标准
  - 入口类：`namespace <name> { public class ModBehaviour : TeamSoda.Duckov.Core.Duckov.Modding.ModBehaviour { ... } }`
  - 对外暴露：通过订阅分布式事件实现联动；避免全局状态写入，除非通过既有 `SavesSystem` 键。
  - 与管理器交互：使用 `GameManager.ModManager` 与事件；不直接操作内部字典。
- 错误处理机制
  - 使用 `try-catch` 包裹外部资源访问与反射调用，返回明确状态并记录日志。
  - 对不可恢复错误通过事件或返回值上报；避免未捕获异常传播至引擎主循环。
  - 使用错误码与统一消息前缀，指明模块与动作。
- 日志记录格式
  - 等级：`Info`、`Error`、`Exception` 对应 `Debug.Log`、`Debug.LogError`、`Debug.LogException`。
  - 前缀：`[Mod:<name>]`；字段：`action`、`result`、`id?`、`elapsed?`。
  - 不记录敏感信息（令牌、私钥、账户）。

## 必要文件清单
- `info.ini`
  - 键：`name`（必填）、`displayName`（可选）、`description`（可选）、`publishedFileId`（可选）
  - 示例：
    - `name=MyAwesomeMod`
    - `displayName=My Awesome Mod`
    - `description=Adds new features`
    - `publishedFileId=0`
- `preview.png`
  - 位置：`<mod_folder>/preview.png`；建议 256×256；可按需压缩。
- `<name>.dll`
  - 位置：`<mod_folder>/<name>.dll`；类型名：`<name>.ModBehaviour`；需引用核心 API。
- 说明文档（可选）
  - `README.txt/md`：使用说明与变更记录。
- 资源文件
  - 建议置于 Mod 文件夹内或其子目录；以相对路径访问；按需加载与释放。

## 依赖包管理
- 引用的核心库（由游戏运行时提供）
  - `UnityEngine`（运行时与日志接口）。
  - `TeamSoda.Duckov.Core`（`ModManager`、`ModBehaviour`、`SavesSystem` 等）。
  - `ItemStatsSystem`（效果与触发管线）。
- 管理器内部依赖
  - `ES3`：用于优先级持久化（ModManager.cs:95-154）；Mod 不必直接依赖。
- 版本兼容性要求
  - 类型命名与继承规则稳定；事件命名基于 `On*` 保持兼容。
  - 建议采用语义化版本记录变更；避免破坏性更改已发布事件与键名。

## 开发环境配置指南
- 安装与版本
  - Unity 编辑器（建议 LTS）；.NET 兼容 `netstandard2.1`。
- 引用设置
  - 在 Mod 工程中引用 `TeamSoda.Duckov.Core.dll` 与必要的 API 稳定接口。
- 构建步骤
  - 编译生成 `<name>.dll`；确认入口类与命名空间一致。
- 放置路径
  - 将 `<name>.dll`、`info.ini`、`preview.png` 放入 `Application.dataPath/Mods/<name>/`。

## 项目结构说明
- 示例结构
  - `MyAwesomeMod/`
    - `src/`
    - `info.ini`
    - `preview.png`
    - `build/`
    - `<name>.dll`

## API 调用示例
- 入口类
```csharp
namespace MyAwesomeMod
{
    public class ModBehaviour : TeamSoda.Duckov.Core.Duckov.Modding.ModBehaviour
    {
        protected override void OnAfterSetup()
        {
        }
        protected override void OnBeforeDeactivate()
        {
        }
    }
}
```
- 订阅 ModManager 事件
```csharp
using TeamSoda.Duckov.Core.Duckov.Modding;

public class Listener
{
    public Listener()
    {
        ModManager.OnModStatusChanged += OnStatusChanged;
        ModManager.OnModLoadingFailed += OnLoadingFailed;
    }
    void OnStatusChanged() {}
    void OnLoadingFailed(string dllPath, string message) {}
}
```

## 常见问题解决方案
- DLL 类型命名不符
  - 必须为 `<name>.ModBehaviour` 且继承核心基类（ModManager.cs:430-451）。
- `info.ini` 缺失或键非法
  - 缺少 `name` 直接失败；缺少其他键将回退并记录错误（ModManager.cs:303-318）。
- `publishedFileId` 非法
  - 解析失败记录错误并按非 Steam 项处理（ModManager.cs:319-330）。
- 重复激活
  - 已激活则拒绝再次激活（ModManager.cs:429）。
- DLL 不存在
  - 路径检查失败并记录错误（ModManager.cs:341）。

## 测试验证方法
- 启用门禁
  - 设置 `AllowActivatingMod=true` 后执行 `ScanAndActivateMods()`（ModManager.cs:29-36, 54-73）。
- UI 验证
  - 通过 Mod 管理 UI 激活/停用与重排（ModManagerUI.cs:84-100；ModEntry.cs:25-31, 64-73）。
- 事件监听
  - 监听 `OnScan`、`OnModActivated`、`OnModStatusChanged`、`OnModLoadingFailed` 验证流程完整性。
- 日志检查
  - 检视 `Debug.Log/Error/Exception` 输出，确认错误路径与消息一致。

## 部署发布流程
- 构建
  - 生成 `<name>.dll` 并完成签名与版本号标注。
- 打包
  - 组织 `info.ini`、`preview.png` 与 DLL；确认键合法。
- 放置与验证
  - 拷贝至 `Application.dataPath/Mods/<name>/`；运行并通过 UI 验证激活。
- 版本记录
  - 更新变更日志与兼容性说明；如发布至平台，维护 `publishedFileId`。

## 参考索引
- ModManager：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModManager.cs:18, 23-36, 54-73, 76-91, 93-154, 156-166, 170-176, 191-208, 209-230, 246-270, 276-357, 343-350, 379-414, 417-495, 522
- ModBehaviour：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModBehaviour.cs:12, 17, 20-25, 28-31, 34-41
- ModInfo：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/ModInfo.cs:7-13
- Trigger/Effect：duckovAPI/Decompilation/ItemStatsSystem/EffectTrigger.cs:33-36；duckovAPI/Decompilation/ItemStatsSystem/Effect.cs:117-135
- UI：duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/UI/ModManagerUI.cs:40, 56, 63, 70, 84, 100, 129；duckovAPI/Decompilation/TeamSoda.Duckov.Core/Duckov/Modding/UI/ModEntry.cs:14, 25, 31, 54, 64, 83, 95, 112, 127
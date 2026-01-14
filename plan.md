这是一个经过深度完善、面向高性能和扩展性的开发文档。它整合了你原有的构思，并重点加强了**音频架构（低延迟/低功耗）**、**主题扩展性（Tikey 风格）以及macOS 系统级兼容性**。

---

# Project Plan: macOS 高性能机械键盘音效引擎 (BarSound)

## 1. 项目愿景 (Vision)

构建一个驻留于 macOS 菜单栏的轻量级应用，提供零延迟、高保真的键盘敲击音效反馈。核心设计原则是 **"隐形与高效"**：在提供沉浸式体验的同时，确保对系统资源的占用（CPU/Energy）几乎不可感知，并支持高度定制化的音效主题（如 Tikey/Tahoe 风格）。

## 2. 核心架构设计 (Architecture)

### 2.1 模块划分

应用将采用 **MVVM** 架构，并包含以下三个核心子系统：

1. **AudioCore (音频引擎)**: 基于 `AVAudioEngine` 的高性能播放池。
2. **InputMonitor (输入监听)**: 负责全局按键捕获、权限管理及安全模式检测。
3. **ThemeManager (主题管理)**: 负责加载 JSON 配置驱动的音效包。

### 2.2 技术栈

* **Language**: Swift 5.x
* **UI Framework**: SwiftUI (MenuBarExtra)
* **Audio Framework**: `AVFoundation` (AVAudioEngine, AVAudioPCMBuffer)
* **System Event**: `CoreGraphics` (CGEvent) / `Cocoa` (NSEvent)

---

## 3. 详细实施步骤 (Implementation Steps)

### Phase 1: 基础架构与菜单栏入口

**目标**: 建立应用骨架，去除 Dock 图标，仅保留 Menu Bar 交互。

* **UI 改造**: 使用 SwiftUI 的 `MenuBarExtra` 替代 `WindowGroup`。
* **Info.plist 配置**: 设置 `LSUIElement` 为 `YES` (Application is agent (UIElement))，隐藏 Dock 图标。
* **UI 布局**:
* 参考截图，放弃传统下拉菜单列表，构建一个基于 `LazyVGrid` 的 **Grid Picker** 视图，用于展示音效图标（如：打字机、马里奥、白轴）。
* 顶部包含：全局开关、音量滑块。
* 底部包含：退出按钮、设置入口。



### Phase 2: 高性能音频引擎 (AudioCore) - *关键性能点*

**目标**: 解决 `AVAudioPlayer` 带来的 I/O 延迟和高内存抖动问题。

* **核心类 `AudioEngineManager**`:
* **单例模式**: 维护唯一的 `AVAudioEngine` 实例。
* **内存驻留 (Pre-warming)**: 在切换主题时，将该主题所有 WAV/MP3 文件解码为 `AVAudioPCMBuffer` 并常驻内存。**严禁**在按键时读取磁盘。


* **并发复用池 (Node Pooling)**:
* 创建包含 5-8 个 `AVAudioPlayerNode` 的对象池。
* **播放逻辑**: 当按键触发 -> 从池中获取空闲 Node -> 挂载 Buffer -> `play()` -> 播放结束重置 Node。
* **防爆音逻辑**: 设定最大并发数（Max Polyphony）。若所有 Node 均忙，根据策略（Fade-out 最旧的声音）强制回收一个 Node 给新按键使用。


* **音调微调 (Pitch Shifting)**:
* 为了模拟真实感，允许对同一音效叠加微小的随机音调变化（Pitch Variance ±0.05），避免“机关枪”效应。



### Phase 3: 全局监听与安全输入 (InputMonitor)

**目标**: 准确捕获按键，同时处理 macOS 复杂的隐私权限。

* **权限请求**: 启动时检查辅助功能权限 (`AXIsProcessTrusted`)，未授权则弹出引导窗口。
* **事件监听**: 使用 `NSEvent.addGlobalMonitorForEvents(matching: .keyDown)`。
* **安全输入模式 (Secure Input) 处理 - *必须考虑***:
* **问题**: 当用户在密码框输入时，macOS 会屏蔽全局事件监听。
* **对策**: 监听系统通知（需使用 C API 或相关 Notification），检测到 Secure Input 开启时，自动暂停音频引擎，并将菜单栏图标置灰，提示用户“安全模式下静音”。


* **去抖动 (Debounce)**:
* 实现一个微秒级的时间戳过滤器，忽略物理键盘可能产生的极短时间内的双击（Double Trigger）。



### Phase 4: 音效包与数据结构 (ThemeManager)

**目标**: 适配 Tikey/Tahoe 风格，实现配置驱动的音效扩展。

* **数据结构 (JSON)**: 定义统一的音效包格式。
```json
{
    "id": "theme_mario",
    "name": "马里奥",
    "icon": "mario_icon.png",
    "base_volume": 1.0,
    "sounds": {
        "default": "jump.wav",
        "enter": "pipe_down.wav",
        "space": "coin.wav",
        "backspace": "shrink.wav",
        "modifier": "fireball.wav"
    }
}

```


* **资源管理**:
* 将音效文件归档在 `.bundle` 或特定的资源目录下。
* 支持用户导入自定义音效包（解压 -> 校验 JSON -> 存入 App Sandbox）。



### Phase 5: 性能优化与能耗控制 (Optimization)

**目标**: 确保后台运行 CPU 占用率 < 1%。

* **Main Thread Isolation**: 所有的音频处理逻辑（选取 Buffer、调度 Node）必须在后台串行队列 (`DispatchQueue`) 执行，绝对不能阻塞主线程 UI。
* **WPM (Words Per Minute) 策略**:
* 计算 WPM 仅用于动态调整音量（可选：打字越快，声音稍微越小，防止刺耳），不做复杂的统计分析。


* **自动休眠**: 若 10 秒无按键，暂停 `AVAudioEngine` 以节省 DSP 功耗；检测到按键时瞬间唤醒（需测试唤醒延迟，若延迟高则保持引擎运行但断开 Output Node）。

---

## 4. 风险评估与应对 (Risk & Mitigation)

| 风险点 | 描述 | 应对方案 |
| --- | --- | --- |
| **音频延迟** | 蓝牙耳机下可能存在显著延迟 | 提供“低延迟模式”开关，强制减小 Buffer Size，但需警告可能增加功耗。 |
| **系统静音** | App 音效不受系统静音键控制 | 监听系统音量改变通知，或遵循系统各知会音量。 |
| **沙盒限制** | Mac App Store 审核对辅助功能权限敏感 | 需在提交审核时详细录制视频说明为何需要 `GlobalMonitor`（这是核心功能）。 |
| **文件丢失** | 用户删除了外部导入的音效包 | 实现资源完整性校验，缺少文件时回退到默认“白轴”音效。 |

## 5. UI/UX 详细设计规范 

* **Grid Layout**: 使用 `LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))])`。
* **选中态**: 当前选中的音效图标增加高亮边框或对钩（Checkmark）。
* **动态反馈**:
* 当用户点击音效图标时，立即播放一次该音效的 `default` 声音作为试听。


* **Tahoe 适配**:
* UI 背景支持半透明模糊材质 (`.regularMaterial`)。
* 字体遵循 macOS Human Interface Guidelines。




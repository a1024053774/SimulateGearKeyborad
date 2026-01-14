# BarSound 🎹

<p align="center">
  <img src="https://img.shields.io/badge/Platform-macOS-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.x-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/License-MIT-green.svg" alt="License">
</p>

**BarSound** 是一款驻留于 macOS 菜单栏的轻量级机械键盘音效模拟应用。每次敲击键盘都能获得悦耳的机械键盘音效反馈，让打字变得更有乐趣！

## ✨ 功能特性

- 🎯 **菜单栏应用** - 无 Dock 图标，静默运行
- 🎨 **7 套音效主题** - 打字机、气泡、机械轴、剑击、架子鼓、Cherry G80 系列
- ⚡ **低延迟播放** - 基于 AVAudioEngine 的高性能音频引擎
- 🔊 **音量控制** - 自定义音效音量
- 🔒 **安全模式** - 密码输入时自动静音
- 💾 **记忆设置** - 自动保存上次选择的主题

## 📸 截图

<!-- 可以添加应用截图 -->

## 🚀 安装

### 系统要求
- macOS 13.0 (Ventura) 或更高版本
- 需要授予辅助功能权限

### 从源码编译
1. 克隆仓库
   ```bash
   git clone https://github.com/a1024053774/SimulateGearKeyborad.git
   ```
2. 使用 Xcode 打开 `SimulateGearKeyborad.xcodeproj`
3. Build & Run (⌘R)
4. 首次运行时授予辅助功能权限

## 🎵 音效主题

| 主题 | 描述 |
|------|------|
| Bubble | 清脆的气泡音效 |
| Typewriter | 复古打字机音效 |
| Mechanical | 机械键盘轴体音效 |
| Sword | 剑击音效 |
| Drum | 架子鼓音效 |
| Cherry G80-3000 | Cherry 青轴音效 |
| Cherry G80-3494 | Cherry 茶轴音效 |

## 🏗️ 技术架构

```
SimulateGearKeyborad/
├── AudioCore/           # 高性能音频引擎
│   └── AudioEngineManager.swift
├── InputMonitor/        # 全局键盘监听
│   └── KeyboardMonitor.swift
├── ThemeManager/        # 主题管理
│   ├── AudioScheme.swift
│   └── ThemeManager.swift
├── SoundData/           # 音效资源
│   ├── schemes.json
│   └── [7 个音效包目录]
├── AppController.swift  # 应用控制器
└── ContentView.swift    # SwiftUI 界面
```

## 🙏 致谢

### 开源项目

本项目的音效资源和设计灵感来源于 [**Tickeys**](https://github.com/yingDev/Tickeys) 开源项目，感谢 [@yingDev](https://github.com/yingDev) 和所有贡献者的无私分享！

> Tickeys 是一个优秀的 Rust + OpenAL 实现的机械键盘音效应用，BarSound 在其基础上使用现代 Swift + SwiftUI + AVAudioEngine 重新实现，以获得更好的 macOS 原生体验。

### AI 助手

特别感谢 **Claude** (Anthropic) 在整个开发过程中提供的智能编程辅助！从架构设计、代码实现到问题调试，Claude 都给予了专业而耐心的帮助，大大提升了开发效率。🤖❤️

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

音效资源版权归原作者所有，请参阅各音效包目录下的 license.txt 文件。

---

<p align="center">
  Made with ❤️ and ⌨️
</p>

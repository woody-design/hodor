[![English](https://img.shields.io/badge/English-454545?style=flat-square)](README.md)
[![简体中文](https://img.shields.io/badge/简体中文-454545?style=flat-square)](README.zh.md)

# Hodor

把你保存的 prompt 一键发送到任何 AI 工具。一个手势——屏幕边缘触发、键盘快捷键或关键词——你的 prompt 就粘贴到了光标所在的位置。

[![Build](https://github.com/woody-design/hodor/actions/workflows/build.yml/badge.svg)](https://github.com/woody-design/hodor/actions/workflows/build.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat-square)](LICENSE)

**[hodor.design](https://hodor.design)** — 下载和了解更多

https://github.com/user-attachments/assets/3f64ef62-21f2-4b41-bf66-acd33f1fbe8e

## Hodor 做什么

- **屏幕边缘触发** — 把光标移到屏幕边缘，浏览你的 prompt 列表，点击即粘贴。
- **键盘快捷键** — 给任意 prompt 分配 A–Z 的字母。按下 `Ctrl+Opt+R`，prompt 立即粘贴。
- **关键词展开** — 设置一个关键词，比如 `;git`。在任何地方输入它，prompt 就会原地出现。

三种方式做同一件事：把你保存的 prompt 送到光标，快。

## 设计决策

**一切都在你的机器上。** 整个代码库没有任何网络请求——没有分析、没有遥测、没有更新检查。你的 prompt 永远不会离开你的 Mac。你可以验证：在源码里搜索 `URLSession`——它不存在。

**原生 macOS，不是 Electron。** Hodor 使用 SwiftUI 和 SwiftData 构建。没有 web view，没有打包的浏览器。应用只有几 MB，不是几百 MB。

**Accessibility 权限——仅此而已。** Hodor 使用 `CGEvent` 向其他应用粘贴内容，和 Raycast、Alfred 的方式一样。源代码就在这里——你可以看到它做了什么、没做什么。

**以 GPL v3 开源。** 每一行代码都是公开的。如果 Hodor 能访问你的 prompt，你应该能验证它对你的数据做了什么。

## 安装

从 **[hodor.design](https://hodor.design)** 下载最新 DMG。需要 macOS 26 或更高版本。

## 从源码构建

前置条件：[Xcode](https://developer.apple.com/xcode/)，需包含 macOS 26 SDK。

```bash
git clone https://github.com/woody-design/hodor.git
cd hodor
```

设置代码签名：
```bash
cp Local.xcconfig.template Local.xcconfig
# 编辑 Local.xcconfig — 填入你的 DEVELOPMENT_TEAM
```

在 Xcode 中打开 `PromptPal.xcodeproj`，然后 build and run。

> 项目使用 [XcodeGen](https://github.com/yonaskolb/XcodeGen) 从 `project.yml` 生成 Xcode 项目。生成的 `.xcodeproj` 已提交到 repo，所以你不需要安装 XcodeGen 来构建——只有在修改项目结构时才需要。

## 反馈

- **Bug 报告** — [提交 issue](https://github.com/woody-design/hodor/issues/new/choose)
- **功能建议** — [发起讨论](https://github.com/woody-design/hodor/discussions/new?category=ideas) — 为你想要的功能投票
- **提问** — [在讨论区提问](https://github.com/woody-design/hodor/discussions/new?category=q-a)

## 许可证

[GPL v3](LICENSE) — 由 [Woody](https://woodydesign.io/) 设计于纽约。

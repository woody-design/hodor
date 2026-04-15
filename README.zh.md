[English](https://github.com/woody-design/hodor)
[简体中文](README.zh.md)

# Hodor

轻量的 prompt 启动器，专为你的 AI 工作流。

每天都在用 AI，prompt 越攒越多。放在备忘录里找不到，放在文档里改不动，每次都得从同一个地方复制粘贴。
Hodor 就做一件事：一个地方集中存，一个动作粘贴到任何 AI 工具里。

免费开源 · 完全本地，无网络请求 · macOS 26+（liquid glass）

[License: GPL v3](LICENSE)

**[hodor.design](https://hodor.design)** — 下载和演示

[https://github.com/user-attachments/assets/3f64ef62-21f2-4b41-bf66-acd33f1fbe8e](https://github.com/user-attachments/assets/3f64ef62-21f2-4b41-bf66-acd33f1fbe8e)

- [三种使用方式](#三种使用方式)
- [设计选择](#设计选择)
- [安装](#安装)
- [常见问题](#常见问题)
- [设计初衷](#设计初衷)

## 三种使用方式

- **屏幕边缘** — 鼠标滑到屏幕边缘，弹出 prompt 列表，点击即粘贴。也可以按 `Ctrl+Opt+Space` 打开侧边栏。
- **快捷键** — 给任意 prompt 分配一个字母 A-Z。按 `Ctrl+Opt+A-Z`，直接粘贴。
- **关键词** — 设一个关键词，比如 `;kit`。在任何地方输入，prompt 原地替换。

三种方式做同一件事：把 prompt 送到当前输入框——如果没有聚焦的输入框，就复制到剪贴板。侧边栏适合浏览，快捷键和关键词让你不用离开键盘。

## 设计选择

- **所有数据都在你的电脑上。** prompt 不会离开你的 Mac。整个代码库没有任何网络请求——不做分析，不做遥测，不检查更新。不弹通知，引导流程做到最简——打开就能用，用完关掉就好。
- **原生 macOS，不是 Electron。** SwiftUI + SwiftData 构建。没有 web view，没有打包的浏览器。整个 app 640 KB。
- **只需要辅助功能权限。** Hodor 用 macOS 辅助功能 API 向其他 app 粘贴内容——和 Raycast、Alfred 同样的方式。源码就在这里，做了什么、没做什么，一看便知。
- **免费开源。** 一个完全本地、没有运营成本的小工具，作者认为应该免费。所有代码以 GPL v3 公开。

## 安装

从 **[hodor.design](https://hodor.design)** 下载最新 DMG。需要 macOS 26 或更高版本。

## 常见问题

### 为什么需要辅助功能权限？

Hodor 通过 macOS 辅助功能 API 模拟 Cmd+V，向其他 app 粘贴 prompt。同一个权限也用于检测快捷键（`Ctrl+Opt` + 字母）和关键词输入。仅此而已——Hodor 不记录按键、不读取屏幕内容、不访问其他 app 的数据。

### 点了 prompt 但没有粘贴。

prompt 已经在剪贴板了，手动 Cmd+V 即可。通常是因为目标 app 的输入框没有获得焦点。

### 侧边栏和快捷键有什么区别？

侧边栏用来浏览：看一看，点一下，不用记任何东西。快捷键（`Ctrl+Opt` + 字母）和关键词（`;kit`）适合正在打字的时候：prompt 直接出现在输入框里，手不用离开键盘。

### 关键词怎么设比较好？

用符号开头：`;kit`、`/reply`、`.git`。这样打普通单词的时候不会误触发。Hodor 自带四个示例 prompt，展示了这个用法。注意：互为前缀的关键词不能共存（`;ki` 和 `;kit` 会冲突）。

### `Ctrl+Opt+Space` 和输入法切换冲突了。

这是一个已知冲突。如果你使用中英文输入法切换，macOS 很可能已经占用了这个快捷键。建议在系统设置 → 键盘 → 输入法中，把切换快捷键改成 `Ctrl+Space` 或 Caps Lock。自定义全局快捷键可能会在未来版本支持。

### 我的数据存在哪里？

所有 prompt 都存在本地，使用 SwiftData，路径是 `~/Library/Application Support/default.store`。不同步，不上传，不发送。

## 设计初衷

我每天都在用 AI 工具，prompt 越攒越多。Raycast snippets 里一些，备忘录里一些，Notion 里一些，还有个文档越写越长。我就想要一个地方集中存，一次点击就能用。开发前给自己定了个标准：能不能让我真的放弃 Raycast 原来的 snippet 方案？我觉得我做到了。

## 反馈

- **Bug 反馈** — [提交 issue](https://github.com/woody-design/hodor/issues/new/choose)
- **功能建议** — [发起讨论](https://github.com/woody-design/hodor/discussions/new?category=ideas) — 为你想要的功能投票
- **提问** — [在讨论区提问](https://github.com/woody-design/hodor/discussions/new?category=q-a)

## 许可证

[GPL v3](LICENSE) — Designed by [Woody](https://woodydesign.io/) in NY

[![English](https://img.shields.io/badge/English-454545?style=flat-square)](README.md)
[![简体中文](https://img.shields.io/badge/简体中文-454545?style=flat-square)](README.zh.md)

# Hodor

Instantly launch your saved prompts into any AI tool. One gesture — edge trigger, keyboard shortcut, or keyword — and your prompt is pasted right where you're typing.

[![Build](https://github.com/woody-design/hodor/actions/workflows/build.yml/badge.svg)](https://github.com/woody-design/hodor/actions/workflows/build.yml)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat-square)](LICENSE)

**[hodor.design](https://hodor.design)** — download, learn more

https://github.com/woody-design/hodor/raw/main/media/demo.mp4

## What Hodor Does

- **Edge trigger** — move your cursor to the screen edge. Browse your prompts, click to paste.
- **Keyboard shortcut** — assign any letter A–Z. Press `Ctrl+Opt+R` and your prompt is pasted instantly.
- **Keyword expansion** — set a keyword like `;git`. Type it anywhere and your prompt appears in place.

All three do the same thing: get your saved prompt to the cursor, fast.

## Design Decisions

**Everything stays on your machine.** There are zero network requests in the entire codebase — no analytics, no telemetry, no update checks. Your prompts never leave your Mac. You can verify this: search the source for `URLSession` — it's not there.

**Native macOS, not Electron.** Hodor is built with SwiftUI and SwiftData. No web views, no bundled browser. The app is a few megabytes, not hundreds.

**Accessibility permission — and nothing more.** Hodor uses `CGEvent` to paste into other apps, the same approach as Raycast and Alfred. The source code is right here — you can see exactly what it does and what it doesn't.

**Open source under GPL v3.** Every line of code is public. If Hodor has access to your prompts, you should be able to verify what it does with them.

## Install

Download the latest DMG from **[hodor.design](https://hodor.design)**. Requires macOS 26 or later.

## Build from Source

Prerequisites: [Xcode](https://developer.apple.com/xcode/) with macOS 26 SDK.

```bash
git clone https://github.com/woody-design/hodor.git
cd hodor
```

Set up code signing:
```bash
cp Local.xcconfig.template Local.xcconfig
# Edit Local.xcconfig — fill in your DEVELOPMENT_TEAM
```

Open `PromptPal.xcodeproj` in Xcode, then build and run.

> The project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`. The generated `.xcodeproj` is committed so you don't need XcodeGen to build — only if you want to modify the project structure.

## Feedback

- **Bug reports** — [open an issue](https://github.com/woody-design/hodor/issues/new/choose)
- **Feature requests** — [start a discussion](https://github.com/woody-design/hodor/discussions/new?category=ideas) — upvote ideas you want to see
- **Questions** — [ask in discussions](https://github.com/woody-design/hodor/discussions/new?category=q-a)

## License

[GPL v3](LICENSE) — Designed by [Woody](https://woodydesign.io/) in NY.

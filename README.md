[![English](https://img.shields.io/badge/English-454545?style=flat-square)](README.md)
[![简体中文](https://img.shields.io/badge/简体中文-454545?style=flat-square)](README.zh.md)

# Hodor

A lightweight prompt launcher for macOS 26+ (liquid glass). 

You have prompts worth keeping — saved in notes, buried in docs, copy-pasted from the same place every time. Hodor gives you one place to save them and one gesture to paste them into any AI tool.

Your AI prompt workflow deserves its own app. 

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg?style=flat-square)](LICENSE)

Free and open source · All local, no network

**[hodor.design](https://hodor.design)** — download and demo

https://github.com/user-attachments/assets/3f64ef62-21f2-4b41-bf66-acd33f1fbe8e

- [Three Ways to Use It](#three-ways-to-use-it)
- [Design Choices](#design-choices)
- [Install](#install)
- [FAQ](#faq)
- [Why I Built This](#why-i-built-this)

## Three Ways to Use It

- **Screen edge** — Slide to the screen edge. Browse your prompts, click to paste. (Or press `Ctrl+Opt+Space` to open from the keyboard.)
- **Shortcut** — Assign a letter A-Z to any prompt. Press `Ctrl+Opt+R` and it's pasted instantly.
- **Keyword** — Set a keyword like `;kit`. Type it anywhere and your prompt replaces it in place.

All three get your prompt into the active text field — or onto your clipboard if nothing is focused. The sidebar is for browsing. Shortcuts and keywords keep your hands on the keyboard.

## Design Choices

- **Everything stays on your machine.** Your prompts never leave your Mac. Zero network requests in the entire codebase — no analytics, no telemetry, no update checks. You can verify: search the source for `URLSession` — it's not there.

- **No interruptions.** No notifications, no "rate this app" prompts, minimal onboarding, no update nags. You open it, you use it, it gets out of your way.

- **Native macOS, not Electron.** Built with SwiftUI and SwiftData. No web views, no bundled browser. The app is 640 KB.

- **Accessibility permission — and nothing more.** Hodor uses macOS Accessibility APIs to paste into other apps — the same approach as Raycast and Alfred. The source code is right here. You can see exactly what it does and what it doesn't.

- **Free and open source.** A small tool that runs locally with no infrastructure costs should be free. Every line of code is public under GPL v3.

## Install

Download the latest DMG from **[hodor.design](https://hodor.design)**. Requires macOS 26 or later.

## FAQ

### Why does Hodor need Accessibility permission?

To paste prompts into other apps, Hodor simulates Cmd+V through macOS Accessibility APIs. The same permission lets it detect per-prompt shortcuts (`Ctrl+Opt` + letter) and keyword typing. That's all it's used for — Hodor doesn't record keystrokes, read screen content, or access other apps' data.

### I clicked a prompt but nothing was pasted.

Your prompt is on the clipboard. Press Cmd+V to paste manually. This usually happens when no text field is focused in the target app.

### What's the difference between the sidebar and shortcuts?

The sidebar is for browsing — find and click, no memorization needed. Shortcuts (`Ctrl+Opt` + letter) and keywords (`;kit`) are for when you're already typing — your prompt appears without leaving the text field.

### How should I set up keywords?

Start keywords with a symbol: `;kit`, `/reply`, `.git`. This prevents Hodor from triggering when you type normal words. Hodor ships with four seed prompts that show this pattern. One caveat: keywords that are prefixes of each other can't coexist (`;ki` and `;kit` would conflict).

### `Ctrl+Opt+Space` conflicts with my input method switching.

This is a known conflict. If you switch between input languages, macOS may already use this shortcut. Try changing your input method shortcut to `Ctrl+Space` or Caps Lock in System Settings > Keyboard. Custom hotkeys are planned for a future version.

### Where is my data stored?

All prompts are stored locally on your Mac using SwiftData, in `~/Library/Application Support/default.store`. Nothing is synced, uploaded, or sent anywhere.

## Why I Built This

I work with AI tools every day and kept a growing collection of prompts — scattered across Raycast snippets, Notion & Apple Notes, and a doc that kept getting longer. I wanted one place to save them and one click to use them. The test I set: could I actually stop using Raycast's snippet system for this? I did.

## Feedback

- **Bug reports** — [open an issue](https://github.com/woody-design/hodor/issues/new/choose)
- **Feature requests** — [start a discussion](https://github.com/woody-design/hodor/discussions/new?category=ideas) — upvote ideas you want to see
- **Questions** — [ask in discussions](https://github.com/woody-design/hodor/discussions/new?category=q-a)

## License

[GPL v3](LICENSE) — Designed by [Woody](https://woodydesign.io/) in NY

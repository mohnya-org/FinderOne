# FinderOne

A lightweight macOS menu bar app that automatically merges Finder windows into a single tabbed window.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## What It Does

Every time you open a new Finder window, FinderOne detects it and merges all Finder windows into one tabbed window — automatically.

No more cluttered desktops full of Finder windows.

## Features

- Automatic merging of new Finder windows into tabs
- Manual "Merge Now" for on-demand merging
- Launch at Login support
- Minimal resource usage — sits quietly in your menu bar

## Installation

> Requires Xcode 15+ and macOS 14+.

```bash
git clone https://github.com/Moomo/FinderOne.git
cd FinderOne
make build
make run
```

## Setup

1. Launch FinderOne — it appears in your menu bar
2. Click the menu bar icon and grant **Accessibility** permission when prompted
3. That's it — new Finder windows will be automatically merged into tabs

### Permissions

| Permission | Why |
|---|---|
| **Accessibility** | Required to monitor Finder windows |
| **Automation** | macOS will prompt on first merge (AppleScript → Finder) |

## How It Works

1. Monitors standard Finder windows via the Accessibility API
2. When multiple windows exist, waits ~0.5s for loading before merging
3. Runs Finder's built-in `Merge All Windows` command via AppleScript
4. Waits for the merge to finish and restores the tab that was frontmost immediately before merging
5. Retries after a short cooldown if multiple windows remain, including after startup or a temporarily unavailable menu command

## Building

This is an Xcode project (not a Swift Package).

```bash
make build        # Build
make debug-build  # Debug build
make clean-build  # Clean + build
make run          # Build and open the app
```

<details>
<summary>Raw xcodebuild command</summary>

```bash
xcodebuild \
  -project Corral.xcodeproj \
  -scheme Corral \
  -configuration Debug \
  -derivedDataPath tmp/DerivedData \
  build CODE_SIGNING_ALLOWED=NO
```

</details>

### Release-style build

`make build` writes the app bundle to `dist/FinderOne.app`, matching the release workflow layout.

## Project Structure

```
Corral/
├── CorralApp.swift                    # App entry point
├── AppDelegate.swift                  # App state & orchestration
├── MenuBarView.swift                  # Menu bar UI
├── MenuBarIconFactory.swift           # Menu bar icon
├── FinderWindowMonitor.swift          # Finder window monitoring
├── AppleScriptRunner.swift            # Finder merge via AppleScript
├── AccessibilityPermissionManager.swift
└── LoginItemManager.swift
```

## Known Limitations

- Monitoring is polling-based, not event-driven
- Finder's `Merge All Windows` may be temporarily unavailable depending on Finder state
- Behavior may be affected by future macOS or Finder changes

## Contributing

Issues and pull requests are welcome.

## License

MIT

## 自動アップデート（Sparkle 2）

アプリは定期的に更新を確認し、Sparkle 標準の画面でダウンロード・インストール・再起動します。
「Automatically check for updates」で定期チェックを切り替え、「Check for Updates…」で手動確認できます。
更新操作は Prism Window / FinderOne ではメニューバーのパネル、TartDesk ではアプリメニューにあります。

配布前に GitHub Actions の repository secrets を設定してください。

- `SPARKLE_PRIVATE_KEY`: Sparkle の `generate_keys -x` で書き出した秘密鍵。
- `SPARKLE_PUBLIC_ED_KEY`: 同じ鍵の `generate_keys -p` が表示する公開鍵。

Sparkle のツールは SPM ビルド後の `.build/artifacts/sparkle/Sparkle/bin`、
Xcode では DerivedData の `SourcePackages/artifacts/sparkle/Sparkle/bin` にあります。
`generate_keys --account <app-name>` で鍵を一度だけ生成し、同じ `--account` を
`-p` と `-x` にも指定します。秘密鍵はリポジトリに保存せず、安全にバックアップしてください。
更新を継続できるよう、リリースごとに鍵を生成し直さないでください。

ワークフローは公開鍵をアプリに埋め込み、公証・staple 後の最終 ZIP に署名し、
`appcast.xml` を同じ GitHub Release に添付します。フィードは
`https://github.com/mohnya-org/FinderOne/releases/latest/download/appcast.xml` です。
公開リポジトリの通常リリースが対象です。ZIP とフィードは一緒に公開してください。
次回リリースではバージョンを上げ、`CFBundleVersion` も必ず増加させます
（Prism Window / FinderOne は Actions の run number、TartDesk はリリースバージョン）。

秘密鍵が未設定ならリリースは失敗して停止します。公開鍵を省略した開発ビルドでは更新は無効です。
ローカルで有効にするには、SPM の build-app.sh に `SPARKLE_PUBLIC_ED_KEY` を渡すか、
FinderOne のビルド済み Info.plist の `SUPublicEDKey` に同じ公開鍵を設定してから署名します。
既存の自動更新未対応版からは、最初の対応版だけ手動でインストールする必要があります。

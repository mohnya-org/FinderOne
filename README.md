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

1. Monitors Finder window count via the Accessibility API
2. When a new window is detected, waits ~0.5s for it to finish loading
3. Runs Finder's built-in `Merge All Windows` command via AppleScript
4. If fewer than 2 windows exist, does nothing

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
main への push（PR マージを含む）で次の `vX.Y.Z` を自動採番します。
通常は既存の正式版タグの最大バージョンからパッチ番号を 1 増やします。
他のコミットで使われた未公開タグも予約済みとして飛ばし、タグを上書きしません。
初回タグがない場合は `v0.0.1` です。ソースのバージョンを書き換えるコミットは不要です。
Actions の手動実行では main を選び、任意で `version` に `1.5.0` のような
新しい正式版を指定できます。空欄なら自動採番します。

採番値を配布アプリのバージョンと ZIP 名に埋め込みます。
`CFBundleVersion` は Prism Window / FinderOne では Actions の run number、
TartDesk では採番したリリースバージョンです。
ビルド・署名・公証・フィード生成後にトリガー元コミットへタグを作り、
ZIP・チェックサム・appcast のアップロードが全部成功してから draft を公開します。
これにより Release 公開 Webhook は必要な成果物がそろった状態で通知されます。

失敗した場合は同じ Actions 実行を再実行できます。途中で作成済みの同一コミットの
タグ・draft は再利用し、公開済みなら何も変更しません。新しい正式版より古い
ソースを再公開する実行は拒否します。リリースは直列実行し、実行中のものは中止しません。
GitHub Actions の concurrency により、短時間にマージが続くと待機中の実行は最新のものに
置き換わる場合があります。その場合は最新コミットに含まれる変更をまとめて公開します。

秘密鍵が未設定ならリリースは失敗して停止します。公開鍵を省略した開発ビルドでは更新は無効です。
ローカルで有効にするには、SPM の build-app.sh に `SPARKLE_PUBLIC_ED_KEY` を渡すか、
FinderOne のビルド済み Info.plist の `SUPublicEDKey` に同じ公開鍵を設定してから署名します。
既存の自動更新未対応版からは、最初の対応版だけ手動でインストールする必要があります。

### Apple signing and notarization

Release builds use these GitHub Actions secrets, including organization secrets made available to this repository:

- `APPLE_CERT_BASE64`, `APPLE_CERT_PASSWORD`: Developer ID Application certificate and private key in a base64-encoded PKCS#12 file.
- `APPLE_TEAM_ID`: expected signing team, checked against the imported certificate and signed app.
- `APPLE_API_KEY_ID`, `APPLE_API_ISSUER_ID`, `APPLE_API_PRIVATE_KEY`: App Store Connect API credentials for notarization.

The release workflow builds without Xcode signing, then signs Sparkle and the app with Developer ID and Hardened Runtime, notarizes the archive, and staples the ticket. Before publishing, it extracts the final ZIP and checks the signature, signing team, notarization ticket, and Gatekeeper acceptance. ZIP creation excludes resource-fork and extended-attribute metadata to avoid AppleDouble (`._*`) files breaking framework validation after extraction.

Local `make build` / `make debug-build` builds do not use these organization secrets or perform Developer ID signing and notarization.

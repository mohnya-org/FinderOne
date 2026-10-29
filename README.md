# FinderOne

A lightweight macOS menu bar app that automatically merges Finder windows into a single tabbed window.

![macOS 14+](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange) ![License: MIT](https://img.shields.io/badge/License-MIT-green)

## What It Does

Every time you open a new Finder window, FinderOne detects it and merges all Finder windows into one tabbed window — automatically.

No more cluttered desktops full of Finder windows.

## Features

- Automatic merging of new Finder windows into tabs
- Manual "Merge Now" for on-demand merging
- Automatic updates and manual update checks
- Launch at Login support
- Minimal resource usage — sits quietly in your menu bar

## Installation

> Requires Xcode 15+ and macOS 14+.

```bash
git clone https://github.com/mohnya-org/FinderOne.git
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

## Updates

FinderOne release builds can check for updates automatically. In the menu bar panel, use **Automatically check for updates** to enable or disable automatic checks, or choose **Check for Updates…** to check manually.

If your installed version predates automatic update support, install a current release manually first.

## How It Works

1. Monitors standard Finder windows via the Accessibility API
2. When multiple windows exist and Finder is frontmost, waits ~0.5s for loading before merging; background merges wait until you return to Finder
3. Runs Finder's built-in `Merge All Windows` command via AppleScript
4. Waits for the merge to finish and restores the tab that was frontmost immediately before merging
5. Retries after a short cooldown if multiple windows remain, including after startup or a temporarily unavailable menu command

Automatic merging never activates Finder. The Activity copy button copies all retained log entries in full, including entries hidden or truncated in the panel.

## Building

This is an Xcode project (not a Swift Package).

```bash
make build        # Build
make debug-build  # Debug build
make clean-build  # Clean + build
make run          # Open the built app
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

`make build` writes the app bundle to `dist/FinderOne.app`, matching the release workflow layout. Local builds do not perform Developer ID signing or notarization, and automatic updates are disabled unless configured.

For maintainer setup, signing, notarization, and release instructions, see [Releasing FinderOne](docs/releasing.md).

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

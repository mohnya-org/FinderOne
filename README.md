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

### Download

Download the latest release from the [Releases](https://github.com/Moomo/FinderOne/releases) page.

### Build from Source

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

# FinderOne

FinderOne is a macOS menu bar app that automatically merges newly opened Finder windows into tabs in an existing Finder window.

The project codename is `Corral`, but the shipping app name is `FinderOne`.

## Overview

- Built with Swift and SwiftUI
- Supports macOS 14 and later
- Runs as a menu bar app
- Monitors the number of Finder windows
- Detects newly opened Finder windows
- Waits about 0.5 seconds, then triggers Finder's `Merge All Windows` command via AppleScript
- Supports a launch-at-login toggle

## How It Works

1. FinderOne monitors Finder window count using the Accessibility API.
2. When the window count increases, it treats that as a newly opened Finder window.
3. After a short delay, it runs Finder's `Merge All Windows` command through AppleScript.
4. Finder merges the windows into a single tabbed window using its built-in behavior.

If Finder has fewer than two windows, FinderOne does nothing.

## Permissions

FinderOne depends on the following macOS permissions.

### Accessibility

Accessibility permission is required to monitor Finder windows and interact with Finder's UI.

On first launch, use `Grant Accessibility Permission` from the menu bar UI.

### Automation / Apple Events

Because FinderOne sends AppleScript commands to Finder, macOS may prompt for Automation permission the first time a merge is attempted.

## Menu Bar UI

- `Automatic merge`: Enables or disables automatic merging
- `Merge Now`: Triggers an immediate manual merge
- `Launch at Login`: Controls whether the app starts automatically at login
- Permission guidance is shown when Accessibility is not granted
- Recent activity entries are displayed in the panel

## Build

This repository is an Xcode project, not a Swift Package. Use `xcodebuild`, not `swift build`.

For day-to-day use, prefer the included `Makefile`.

```bash
make build
```

Clean build:

```bash
make clean-build
```

Open the built app:

```bash
make run
```

If you want the raw Xcode command, `make clean-build` expands to:

```bash
xcodebuild \
  -project Corral.xcodeproj \
  -scheme Corral \
  -configuration Debug \
  -derivedDataPath tmp/DerivedData \
  build CODE_SIGNING_ALLOWED=NO
```

Build output:

```text
tmp/DerivedData/Build/Products/Debug/FinderOne.app
```

## Run

After building:

```bash
make run
```

## Project Structure

```text
Corral.xcodeproj/                        Xcode project
Corral/CorralApp.swift                   App entry point
Corral/AppDelegate.swift                 App state and orchestration
Corral/FinderWindowMonitor.swift         Finder window monitoring
Corral/AppleScriptRunner.swift           Finder merge execution
Corral/AccessibilityPermissionManager.swift Permission handling
Corral/LoginItemManager.swift            Launch-at-login handling
Corral/MenuBarView.swift                 Menu bar UI
Corral/MenuBarIconFactory.swift          Custom menu bar icon
Corral/Info.plist                        App bundle settings
Makefile                                Build and run shortcuts
```

## Notes

- If Accessibility permission is granted later in System Settings, opening the menu bar UI forces an immediate permission refresh.
- The AppleScript logic tries both English and Japanese Finder menu names to tolerate localization differences.
- `Launch at Login` is expected to work best when the app is placed in `/Applications`.
- The menu bar UI uses a window-style panel rather than a plain NSMenu so it can support richer SwiftUI controls.

## Known Limitations

- Monitoring is currently polling-based rather than event-driven.
- Finder's `Merge All Windows` command may be temporarily unavailable depending on Finder state.
- Because merging relies on AppleScript and Finder UI automation, behavior may be affected by future macOS or Finder changes.

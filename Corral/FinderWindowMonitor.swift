import AppKit
import ApplicationServices

@MainActor
final class FinderWindowMonitor {
    private let permissionManager: AccessibilityPermissionManager
    private let onWindowIncreaseDetected: () -> Void
    private let onWindowSnapshot: (Int) -> Void
    private let onPermissionChanged: (Bool) -> Void
    private let onLog: (String) -> Void

    private var timer: Timer?
    private var lastKnownWindowCount = 0
    private var hasBaseline = false

    init(
        permissionManager: AccessibilityPermissionManager,
        onWindowIncreaseDetected: @escaping () -> Void,
        onWindowSnapshot: @escaping (Int) -> Void,
        onPermissionChanged: @escaping (Bool) -> Void,
        onLog: @escaping (String) -> Void
    ) {
        self.permissionManager = permissionManager
        self.onWindowIncreaseDetected = onWindowIncreaseDetected
        self.onWindowSnapshot = onWindowSnapshot
        self.onPermissionChanged = onPermissionChanged
        self.onLog = onLog
    }

    func start() {
        guard timer == nil else { return }

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.pollFinderWindows()
            }
        }
        RunLoop.main.add(timer!, forMode: .common)
        pollFinderWindows()
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        lastKnownWindowCount = 0
        hasBaseline = false
        onWindowSnapshot(0)
    }

    func refreshNow() {
        pollFinderWindows()
    }

    private func pollFinderWindows() {
        let granted = permissionManager.refresh(prompt: false)
        onPermissionChanged(granted)
        guard granted else {
            lastKnownWindowCount = 0
            onWindowSnapshot(0)
            return
        }

        guard let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first else {
            if lastKnownWindowCount != 0 {
                onLog("Finder is not running.")
            }
            lastKnownWindowCount = 0
            onWindowSnapshot(0)
            return
        }

        let currentWindowCount = windowCount(for: finder.processIdentifier)
        onWindowSnapshot(currentWindowCount)

        if hasBaseline, currentWindowCount > lastKnownWindowCount {
            onLog("Detected a new Finder window.")
            onWindowIncreaseDetected()
        }

        hasBaseline = true
        lastKnownWindowCount = currentWindowCount
    }

    private func windowCount(for pid: pid_t) -> Int {
        let appElement = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)

        guard result == .success, let windows = value as? [AXUIElement] else {
            return 0
        }

        return windows.count
    }
}

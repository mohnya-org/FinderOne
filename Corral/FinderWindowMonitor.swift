import AppKit
import ApplicationServices

@MainActor
final class FinderWindowMonitor {
    private let permissionManager: AccessibilityPermissionManager
    private let onMultipleWindowsDetected: () -> Void
    private let onWindowSnapshot: (Int) -> Void
    private let onPermissionChanged: (Bool) -> Void
    private let onLog: (String) -> Void

    private var timer: Timer?
    private var lastKnownWindowCount = 0
    private var lastDetectionDiagnostic: String?

    init(
        permissionManager: AccessibilityPermissionManager,
        onMultipleWindowsDetected: @escaping () -> Void,
        onWindowSnapshot: @escaping (Int) -> Void,
        onPermissionChanged: @escaping (Bool) -> Void,
        onLog: @escaping (String) -> Void
    ) {
        self.permissionManager = permissionManager
        self.onMultipleWindowsDetected = onMultipleWindowsDetected
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
        lastDetectionDiagnostic = nil
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

        if currentWindowCount > 1 {
            if currentWindowCount > lastKnownWindowCount {
                onLog("Detected \(currentWindowCount) Finder windows for automatic merge.")
            }
            // Retry even when the previous merge failed without changing the count.
            onMultipleWindowsDetected()
        }
        lastKnownWindowCount = currentWindowCount
    }

    private func windowCount(for pid: pid_t) -> Int {
        let appElement = AXUIElementCreateApplication(pid)
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &value)

        let windows = result == .success ? (value as? [AXUIElement] ?? []) : []
        let standardCount = windows.filter { window in
            var subrole: CFTypeRef?
            guard AXUIElementCopyAttributeValue(window, kAXSubroleAttribute as CFString, &subrole) == .success else {
                return false
            }
            return subrole as? String == kAXStandardWindowSubrole
        }.count

        // AX can omit newly created windows or expose a different subrole.
        // Use visible WindowServer windows as a second signal; the enabled Finder
        // merge menu remains the authority on whether these can actually merge.
        let visibleWindows = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID
        ) as? [[String: Any]] ?? []
        let visibleCount = Self.visibleFinderWindowCount(visibleWindows, pid: pid)
        let diagnostic = "Finder detection: AX standard=\(standardCount), AX total=\(windows.count), visible=\(visibleCount), AX error=\(result.rawValue)."
        if diagnostic != lastDetectionDiagnostic {
            onLog(diagnostic)
            lastDetectionDiagnostic = diagnostic
        }
        return max(standardCount, visibleCount)
    }

    nonisolated static func visibleFinderWindowCount(_ windows: [[String: Any]], pid: pid_t) -> Int {
        windows.filter { window in
            guard (window[kCGWindowOwnerPID as String] as? NSNumber)?.int32Value == pid,
                  (window[kCGWindowLayer as String] as? NSNumber)?.intValue == 0,
                  let bounds = window[kCGWindowBounds as String] as? [String: Any],
                  let width = bounds["Width"] as? NSNumber,
                  let height = bounds["Height"] as? NSNumber else { return false }
            return width.doubleValue > 0 && height.doubleValue > 0
        }.count
    }
}

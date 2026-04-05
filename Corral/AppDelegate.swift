import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let appState = AppState()

    func applicationDidFinishLaunching(_ notification: Notification) {
        appState.start()
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        appState.refreshPermission(prompt: false)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.stop()
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var isEnabled = true {
        didSet {
            guard oldValue != isEnabled else { return }
            if isEnabled {
                log("Automatic merge enabled.")
                finderWindowMonitor.start()
            } else {
                log("Automatic merge paused.")
                finderWindowMonitor.stop()
            }
        }
    }
    @Published var accessibilityGranted = false
    @Published var launchAtLogin = false
    @Published var isMergingNow = false
    @Published var statusText = "Starting up..."
    @Published private(set) var logs: [String] = []
    @Published private(set) var launchAtLoginHint: String?

    var menuBarIconState: MenuBarIconState {
        if !accessibilityGranted {
            return .warning
        }
        if isEnabled {
            return .active
        }
        return .paused
    }

    let permissionManager = AccessibilityPermissionManager()
    let appleScriptRunner = AppleScriptRunner()
    let loginItemManager = LoginItemManager()
    lazy var finderWindowMonitor = FinderWindowMonitor(
        permissionManager: permissionManager,
        onWindowIncreaseDetected: { [weak self] in
            self?.scheduleAutomaticMerge()
        },
        onWindowSnapshot: { [weak self] count in
            self?.statusText = count > 0 ? "Finder windows: \(count)" : "Finder not running or no windows."
        },
        onPermissionChanged: { [weak self] granted in
            guard let self else { return }
            let previousValue = self.accessibilityGranted
            self.accessibilityGranted = granted

            guard previousValue != granted else { return }
            if granted {
                self.log("Accessibility permission granted.")
            } else {
                self.log("Accessibility permission missing.")
            }
        },
        onLog: { [weak self] message in
            self?.log(message)
        }
    )

    private var scheduledMerge: DispatchWorkItem?
    private var permissionFollowUpTask: Task<Void, Never>?

    func start() {
        refreshPermission(prompt: false)
        loginItemManager.refreshStatus()
        launchAtLogin = loginItemManager.isEnabled
        launchAtLoginHint = loginItemManager.unsupportedReason
        statusText = "Waiting for Finder windows..."

        if accessibilityGranted && isEnabled {
            finderWindowMonitor.start()
        } else if !accessibilityGranted {
            log("Open the menu and grant Accessibility permission to start monitoring Finder.")
        }
    }

    func stop() {
        scheduledMerge?.cancel()
        permissionFollowUpTask?.cancel()
        finderWindowMonitor.stop()
    }

    func refreshPermission(prompt: Bool) {
        accessibilityGranted = permissionManager.refresh(prompt: prompt)
        launchAtLoginHint = loginItemManager.unsupportedReason
        if accessibilityGranted {
            if isEnabled {
                finderWindowMonitor.start()
            }
        } else {
            finderWindowMonitor.stop()
        }
    }

    func requestAccessibilityPermission() {
        refreshPermission(prompt: true)
        startPermissionFollowUpPolling()
    }

    func openAccessibilitySettings() {
        permissionManager.openSystemSettings()
        startPermissionFollowUpPolling()
    }

    func mergeNow() {
        scheduledMerge?.cancel()
        Task { await performMerge(trigger: "manual") }
    }

    func updateLaunchAtLogin(_ enabled: Bool) {
        do {
            try loginItemManager.setEnabled(enabled)
            launchAtLogin = loginItemManager.isEnabled
            launchAtLoginHint = loginItemManager.unsupportedReason
            log(enabled ? "Launch at login enabled." : "Launch at login disabled.")
        } catch {
            launchAtLogin = loginItemManager.isEnabled
            launchAtLoginHint = loginItemManager.unsupportedReason
            log("Failed to update launch at login: \(error.localizedDescription)")
        }
    }

    private func scheduleAutomaticMerge() {
        guard isEnabled else { return }
        scheduledMerge?.cancel()
        let preferredTabTitle = appleScriptRunner.frontFinderWindowTitle()
        let preferredTargetPath = appleScriptRunner.frontFinderWindowTargetPath()
        let preferredDocumentToken = appleScriptRunner.frontFinderWindowDocumentToken()

        let workItem = DispatchWorkItem { [weak self] in
            Task {
                await self?.performMerge(
                    trigger: "automatic",
                    preferredTabTitle: preferredTabTitle,
                    preferredTargetPath: preferredTargetPath,
                    preferredDocumentToken: preferredDocumentToken
                )
            }
        }
        scheduledMerge = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: workItem)
    }

    private func startPermissionFollowUpPolling() {
        permissionFollowUpTask?.cancel()
        permissionFollowUpTask = Task { [weak self] in
            guard let self else { return }

            // Allow enough time for the user to navigate System Settings and grant access.
            for _ in 0..<120 {
                try? await Task.sleep(for: .milliseconds(500))
                if Task.isCancelled { return }

                self.refreshPermission(prompt: false)
                if self.accessibilityGranted {
                    return
                }
            }
        }
    }

    private func performMerge(
        trigger: String,
        preferredTabTitle: String? = nil,
        preferredTargetPath: String? = nil,
        preferredDocumentToken: String? = nil
    ) async {
        guard !isMergingNow else { return }
        guard accessibilityGranted else {
            log("Skipping merge because Accessibility permission is not granted.")
            return
        }

        isMergingNow = true
        defer { isMergingNow = false }

        do {
            let result = try appleScriptRunner.mergeFinderWindows(
                preferredTabTitle: preferredTabTitle,
                preferredTargetPath: preferredTargetPath,
                preferredDocumentToken: preferredDocumentToken
            )
            switch result {
            case .merged(let count):
                log("Merged Finder windows via \(trigger) trigger. Remaining windows: \(count).")
            case .skipped(let reason):
                log("Merge skipped: \(reason)")
            }
        } catch {
            log("Merge failed: \(error.localizedDescription)")
        }

        finderWindowMonitor.refreshNow()
    }

    private func log(_ message: String) {
        let timestamp = DateFormatter.logTimestamp.string(from: Date())
        logs.insert("[\(timestamp)] \(message)", at: 0)
        logs = Array(logs.prefix(12))
    }
}

private extension DateFormatter {
    static let logTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}

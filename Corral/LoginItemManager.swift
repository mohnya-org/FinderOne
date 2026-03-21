import ServiceManagement

@MainActor
final class LoginItemManager {
    private(set) var isEnabled = false
    var unsupportedReason: String? {
        guard !Bundle.main.bundlePath.hasPrefix("/Applications/") else { return nil }
        return "Move FinderOne.app to /Applications to enable Launch at Login."
    }

    func refreshStatus() {
        let status = SMAppService.mainApp.status
        isEnabled = status == .enabled || status == .requiresApproval
    }

    func setEnabled(_ enabled: Bool) throws {
        if enabled, let unsupportedReason {
            throw NSError(
                domain: "FinderOne.LoginItemManager",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: unsupportedReason]
            )
        }

        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try SMAppService.mainApp.unregister()
        }

        refreshStatus()
    }
}

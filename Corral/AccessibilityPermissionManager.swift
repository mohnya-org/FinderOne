import ApplicationServices
import AppKit

@MainActor
final class AccessibilityPermissionManager {
    private(set) var isGranted = false

    func refresh(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        isGranted = AXIsProcessTrustedWithOptions(options)
        return isGranted
    }

    func openSystemSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") else {
            return
        }
        NSWorkspace.shared.open(url)
    }
}

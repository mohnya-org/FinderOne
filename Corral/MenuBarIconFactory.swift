import AppKit

enum MenuBarIconFactory {
    static func image(for state: MenuBarIconState) -> NSImage {
        let symbolName: String
        switch state {
        case .active:
            symbolName = "rectangle.on.rectangle"
        case .paused:
            symbolName = "rectangle.on.rectangle.slash"
        case .warning:
            symbolName = "rectangle.badge.xmark"
        }

        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: "FinderOne")!
            .withSymbolConfiguration(config)!

        image.isTemplate = true
        return image
    }
}

enum MenuBarIconState {
    case active
    case paused
    case warning
}

import AppKit

enum MenuBarIconFactory {
    static func image(for state: MenuBarIconState) -> NSImage {
        let size = NSSize(width: 18, height: 18)
        let image = NSImage(size: size)
        image.isTemplate = true

        image.lockFocus()

        let color = NSColor.labelColor
        color.setStroke()
        color.setFill()

        let backWindow = NSBezierPath(roundedRect: NSRect(x: 2.6, y: 5.0, width: 8.4, height: 7.2), xRadius: 1.8, yRadius: 1.8)
        backWindow.lineWidth = 1.8
        backWindow.stroke()

        let frontWindow = NSBezierPath(roundedRect: NSRect(x: 6.8, y: 6.8, width: 8.8, height: 7.6), xRadius: 1.9, yRadius: 1.9)
        frontWindow.lineWidth = 1.8
        frontWindow.stroke()

        let topBar = NSBezierPath()
        topBar.lineWidth = 1.8
        topBar.lineCapStyle = .round
        topBar.move(to: NSPoint(x: 8.6, y: 11.8))
        topBar.line(to: NSPoint(x: 13.9, y: 11.8))
        topBar.stroke()

        switch state {
        case .active:
            break
        case .paused:
            let pauseLeft = NSBezierPath(roundedRect: NSRect(x: 6.1, y: 0.8, width: 1.9, height: 3.8), xRadius: 0.7, yRadius: 0.7)
            let pauseRight = NSBezierPath(roundedRect: NSRect(x: 10.0, y: 0.8, width: 1.9, height: 3.8), xRadius: 0.7, yRadius: 0.7)
            pauseLeft.fill()
            pauseRight.fill()
        case .warning:
            let dot = NSBezierPath(ovalIn: NSRect(x: 8.0, y: 0.8, width: 2.0, height: 2.0))
            dot.fill()

            let stem = NSBezierPath()
            stem.lineWidth = 1.8
            stem.lineCapStyle = .round
            stem.move(to: NSPoint(x: 9.0, y: 4.2))
            stem.line(to: NSPoint(x: 9.0, y: 8.0))
            stem.stroke()
        }

        image.unlockFocus()
        return image
    }
}

enum MenuBarIconState {
    case active
    case paused
    case warning
}

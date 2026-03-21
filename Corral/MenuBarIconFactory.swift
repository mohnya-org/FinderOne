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

        let backWindow = NSBezierPath(roundedRect: NSRect(x: 2, y: 8, width: 8, height: 6), xRadius: 1.5, yRadius: 1.5)
        backWindow.lineWidth = 1.4
        backWindow.stroke()

        let frontWindow = NSBezierPath(roundedRect: NSRect(x: 8, y: 4, width: 8, height: 6), xRadius: 1.5, yRadius: 1.5)
        frontWindow.lineWidth = 1.4
        frontWindow.stroke()

        let mergeArrow = NSBezierPath()
        mergeArrow.lineWidth = 1.6
        mergeArrow.lineCapStyle = .round
        mergeArrow.move(to: NSPoint(x: 5, y: 5))
        mergeArrow.line(to: NSPoint(x: 9.5, y: 5))
        mergeArrow.line(to: NSPoint(x: 9.5, y: 7.3))
        mergeArrow.stroke()

        let arrowHead = NSBezierPath()
        arrowHead.lineWidth = 1.6
        arrowHead.lineCapStyle = .round
        arrowHead.move(to: NSPoint(x: 8.1, y: 6.0))
        arrowHead.line(to: NSPoint(x: 9.5, y: 7.4))
        arrowHead.line(to: NSPoint(x: 10.9, y: 6.0))
        arrowHead.stroke()

        switch state {
        case .active:
            break
        case .paused:
            let pauseLeft = NSBezierPath(roundedRect: NSRect(x: 5.2, y: 1.5, width: 1.8, height: 4.2), xRadius: 0.6, yRadius: 0.6)
            let pauseRight = NSBezierPath(roundedRect: NSRect(x: 8.3, y: 1.5, width: 1.8, height: 4.2), xRadius: 0.6, yRadius: 0.6)
            pauseLeft.fill()
            pauseRight.fill()
        case .warning:
            let dot = NSBezierPath(ovalIn: NSRect(x: 7.4, y: 1.2, width: 1.8, height: 1.8))
            dot.fill()

            let stem = NSBezierPath()
            stem.lineWidth = 1.7
            stem.lineCapStyle = .round
            stem.move(to: NSPoint(x: 8.3, y: 3.9))
            stem.line(to: NSPoint(x: 8.3, y: 7.0))
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

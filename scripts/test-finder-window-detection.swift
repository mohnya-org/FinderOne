import AppKit

@main
struct FinderWindowDetectionTests {
    static func main() {
        let pid: pid_t = 123
        func window(pid: pid_t = 123, layer: Int = 0, width: Double = 800, height: Double = 600) -> [String: Any] {
            [kCGWindowOwnerPID as String: NSNumber(value: pid),
             kCGWindowLayer as String: NSNumber(value: layer),
             kCGWindowBounds as String: ["Width": NSNumber(value: width), "Height": NSNumber(value: height)]]
        }
        let count = FinderWindowMonitor.visibleFinderWindowCount
        precondition(count([], pid) == 0)
        precondition(count([window()], pid) == 1)
        precondition(count([window(), window()], pid) == 2)
        // Other apps, desktop/menu layers, empty windows and incomplete entries
        // must not turn one Finder window into a multiple-window signal.
        precondition(count([window(), window(pid: 456), window(layer: -1),
                            window(layer: 20), window(width: 0), window(height: 0), [:]], pid) == 1)
        print("Finder window detection checks passed")
    }
}

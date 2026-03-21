import Foundation

struct AppleScriptRunner {
    enum MergeResult {
        case merged(Int)
        case skipped(String)
    }

    enum ScriptError: LocalizedError {
        case compileFailure
        case executionFailure(String)
        case malformedResult

        var errorDescription: String? {
            switch self {
            case .compileFailure:
                return "Failed to compile AppleScript."
            case .executionFailure(let message):
                return message
            case .malformedResult:
                return "AppleScript returned an unexpected value."
            }
        }
    }

    func mergeFinderWindows() throws -> MergeResult {
        let script = """
        set mergeMenuNames to {"Merge All Windows", "すべてのウインドウを結合", "すべてのウィンドウを結合"}
        set windowMenuNames to {"Window", "ウインドウ", "ウィンドウ"}

        tell application "Finder"
            if not running then
                return "skip|Finder is not running."
            end if

            set finderWindowCount to count of Finder windows
            if finderWindowCount < 2 then
                return "skip|Finder has fewer than two windows."
            end if

            activate
        end tell

        tell application "System Events"
            tell process "Finder"
                set didMerge to false

                repeat with windowMenuName in windowMenuNames
                    if exists menu bar item (contents of windowMenuName) of menu bar 1 then
                        tell menu bar item (contents of windowMenuName) of menu bar 1
                            tell menu 1
                                repeat with mergeMenuName in mergeMenuNames
                                    if exists menu item (contents of mergeMenuName) then
                                        click menu item (contents of mergeMenuName)
                                        set didMerge to true
                                        exit repeat
                                    end if
                                end repeat
                            end tell
                        end tell
                    end if

                    if didMerge then
                        exit repeat
                    end if
                end repeat

                if not didMerge then
                    return "skip|Finder's Merge All Windows menu item was not available."
                end if
            end tell
        end tell

        delay 0.2

        tell application "Finder"
            return "merged|" & (count of Finder windows)
        end tell
        """

        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else {
            throw ScriptError.compileFailure
        }

        let resultDescriptor = appleScript.executeAndReturnError(&errorInfo)
        if let errorInfo {
            let message = errorInfo[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error."
            throw ScriptError.executionFailure(message)
        }

        guard let output = resultDescriptor.stringValue else {
            throw ScriptError.malformedResult
        }

        if output.hasPrefix("skip|") {
            return .skipped(String(output.dropFirst(5)))
        }

        if output.hasPrefix("merged|"), let count = Int(output.split(separator: "|").last ?? "") {
            return .merged(count)
        }

        throw ScriptError.malformedResult
    }
}

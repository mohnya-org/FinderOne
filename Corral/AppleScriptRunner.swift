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

    func mergeFinderWindows(
        preferredTabTitle: String? = nil,
        preferredTargetPath: String? = nil,
        preferredDocumentToken: String? = nil
    ) throws -> MergeResult {
        let preferredTabTitleLiteral = appleScriptStringLiteral(preferredTabTitle)
        let preferredTargetPathLiteral = appleScriptStringLiteral(preferredTargetPath)
        let preferredDocumentTokenLiteral = appleScriptStringLiteral(preferredDocumentToken)
        let script = """
        set mergeMenuNames to {"Merge All Windows", "すべてのウインドウを結合", "すべてのウィンドウを結合"}
        set windowMenuNames to {"Window", "ウインドウ", "ウィンドウ"}
        set preferredTabTitle to \(preferredTabTitleLiteral)
        set preferredTargetPath to \(preferredTargetPathLiteral)
        set preferredDocumentToken to \(preferredDocumentTokenLiteral)

        on finderFrontWindowTitle()
            tell application "Finder"
                try
                    return name of front Finder window
                on error
                    return missing value
                end try
            end tell
        end finderFrontWindowTitle

        on finderFrontWindowTargetPath()
            tell application "Finder"
                try
                    return POSIX path of (target of front Finder window as alias)
                on error
                    return missing value
                end try
            end tell
        end finderFrontWindowTargetPath

        on finderFrontWindowDocumentToken()
            tell application "System Events"
                tell process "Finder"
                    try
                        return value of attribute "AXDocument" of front window
                    on error
                        return missing value
                    end try
                end tell
            end tell
        end finderFrontWindowDocumentToken

        on standardFinderWindowCount()
            tell application "System Events"
                tell process "Finder"
                    return count of (windows whose subrole is "AXStandardWindow")
                end tell
            end tell
        end standardFinderWindowCount

        on restorePreferredTab(preferredTargetPath, preferredDocumentToken, preferredTabTitle)
            tell application "System Events"
                tell process "Finder"
                    try
                        set tabButtons to radio buttons of tab group 1 of front window
                    on error
                        return false
                    end try
                    repeat with candidateButton in tabButtons
                        try
                            click candidateButton
                            -- Finder's scripting target can lag behind the selected AX tab.
                            repeat 5 times
                                delay 0.05
                                if preferredTargetPath is not missing value then
                                    if my finderFrontWindowTargetPath() is preferredTargetPath then return true
                                end if
                                if preferredDocumentToken is not missing value then
                                    if my finderFrontWindowDocumentToken() is preferredDocumentToken then return true
                                end if
                            end repeat
                            if preferredTargetPath is missing value and preferredDocumentToken is missing value then
                                if preferredTabTitle is not missing value then
                                    if title of candidateButton is preferredTabTitle then return true
                                end if
                            end if
                        end try
                    end repeat
                    return false
                end tell
            end tell
        end restorePreferredTab

        tell application "Finder"
            if not running then
                return "skip|Finder is not running."
            end if

            set finderWindowCount to my standardFinderWindowCount()
            if finderWindowCount < 2 then
                return "skip|Finder has fewer than two windows."
            end if

            -- Capture after the loading debounce, immediately before merging.
            if preferredTabTitle is missing value then set preferredTabTitle to my finderFrontWindowTitle()
            if preferredTargetPath is missing value then set preferredTargetPath to my finderFrontWindowTargetPath()
            if preferredDocumentToken is missing value then set preferredDocumentToken to my finderFrontWindowDocumentToken()
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
                                        if not enabled of menu item (contents of mergeMenuName) then exit repeat
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

        -- Wait for the actual window merge, rather than assuming 200 ms is enough.
        repeat 30 times
            if my standardFinderWindowCount() < 2 then exit repeat
            delay 0.1
        end repeat
        set remainingWindowCount to my standardFinderWindowCount()
        if remainingWindowCount > 1 then
            return "skip|Finder still has multiple windows; will retry."
        end if

        if remainingWindowCount is 1 then
            -- Tab controls may appear after the window animation completes.
            repeat 10 times
                tell application "System Events" to tell process "Finder"
                    set tabsReady to exists tab group 1 of front window
                end tell
                if tabsReady then exit repeat
                delay 0.1
            end repeat
            my restorePreferredTab(preferredTargetPath, preferredDocumentToken, preferredTabTitle)
        end if
        return "merged|" & remainingWindowCount
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

    func frontFinderWindowTitle() -> String? {
        executeOptionalStringScript("""
        tell application "Finder"
            if not running then
                return ""
            end if

            try
                return name of front Finder window
            on error
                return ""
            end try
        end tell
        """)
    }

    func frontFinderWindowTargetPath() -> String? {
        executeOptionalStringScript("""
        tell application "Finder"
            if not running then
                return ""
            end if

            try
                return POSIX path of (target of front Finder window as alias)
            on error
                return ""
            end try
        end tell
        """)
    }

    func frontFinderWindowDocumentToken() -> String? {
        executeOptionalStringScript("""
        tell application "System Events"
            if not (exists process "Finder") then
                return ""
            end if

            tell process "Finder"
                try
                    return value of attribute "AXDocument" of front window
                on error
                    return ""
                end try
            end tell
        end tell
        """)
    }

    private func appleScriptStringLiteral(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "missing value"
        }

        let escapedValue = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return "\"\(escapedValue)\""
    }

    private func executeOptionalStringScript(_ source: String) -> String? {
        var errorInfo: NSDictionary?
        guard let appleScript = NSAppleScript(source: source) else {
            return nil
        }

        let resultDescriptor = appleScript.executeAndReturnError(&errorInfo)
        if errorInfo != nil {
            return nil
        }

        guard let value = resultDescriptor.stringValue, !value.isEmpty else {
            return nil
        }

        return value
    }
}

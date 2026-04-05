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

        tell application "System Events"
            tell process "Finder"
                try
                    tell front window
                        if exists tab group 1 then
                            set tabButtons to radio buttons of tab group 1

                            if preferredTargetPath is not missing value and preferredTargetPath is not "" then
                                repeat with candidateButton in tabButtons
                                    try
                                        click candidateButton
                                        delay 0.05
                                        if finderFrontWindowTargetPath() is preferredTargetPath then
                                            error number -128
                                        end if
                                    end try
                                end repeat
                            end if

                            if preferredDocumentToken is not missing value and preferredDocumentToken is not "" then
                                repeat with candidateButton in tabButtons
                                    try
                                        click candidateButton
                                        delay 0.05
                                        if finderFrontWindowDocumentToken() is preferredDocumentToken then
                                            error number -128
                                        end if
                                    end try
                                end repeat
                            end if

                            if preferredTabTitle is not missing value and preferredTabTitle is not "" then
                                repeat with candidateButton in tabButtons
                                    try
                                        if title of candidateButton is preferredTabTitle then
                                            click candidateButton
                                            error number -128
                                        end if
                                    end try
                                end repeat
                            end if

                            if (count of tabButtons) > 0 then
                                -- Final fallback for windows that expose neither target nor AXDocument.
                                click item -1 of tabButtons
                            end if
                        end if
                    end tell
                on error errMsg number errNum
                    if errNum is not -128 then
                        -- Ignore focus restoration failures and keep the merge successful.
                    end if
                end try
            end tell
        end tell

        delay 0.1

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

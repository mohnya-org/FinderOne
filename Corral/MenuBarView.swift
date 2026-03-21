import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Automatic merge", isOn: $appState.isEnabled)
                .toggleStyle(.switch)
                .disabled(!appState.accessibilityGranted)

            Button(appState.isMergingNow ? "Merging..." : "Merge Now") {
                appState.mergeNow()
            }
            .disabled(appState.isMergingNow || !appState.accessibilityGranted)

            Divider()

            Toggle(
                "Launch at Login",
                isOn: Binding(
                    get: { appState.launchAtLogin },
                    set: { appState.updateLaunchAtLogin($0) }
                )
            )
            .toggleStyle(.switch)

            if !appState.accessibilityGranted {
                Divider()

                Text("Accessibility permission is required to monitor Finder windows.")
                    .font(.footnote)
                    .fixedSize(horizontal: false, vertical: true)

                Button("Grant Accessibility Permission") {
                    appState.requestAccessibilityPermission()
                }

                Button("Open Accessibility Settings") {
                    appState.openAccessibilitySettings()
                }
            }

            Divider()

            Text(appState.statusText)
                .font(.footnote)
                .foregroundStyle(.secondary)

            if !appState.logs.isEmpty {
                Divider()

                ForEach(appState.logs, id: \.self) { entry in
                    Text(entry)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()

            Button("Quit Corral") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding(14)
        .frame(width: 320)
        .onAppear {
            appState.refreshPermission(prompt: false)
        }
    }
}

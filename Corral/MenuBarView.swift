import SwiftUI

struct MenuBarView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
                .padding(.horizontal, 16)
                .padding(.top, 14)
                .padding(.bottom, 10)

            Divider()
                .padding(.horizontal, 12)

            // Content
            ScrollView {
                VStack(spacing: 2) {
                    if !appState.accessibilityGranted {
                        permissionBanner
                            .padding(.horizontal, 12)
                            .padding(.top, 8)
                    }

                    if appState.accessibilityGranted {
                        toggleRow(
                            icon: "rectangle.on.rectangle",
                            iconColor: .blue,
                            title: "Auto Merge",
                            isOn: $appState.isEnabled
                        )

                        mergeNowRow
                    }

                    toggleRow(
                        icon: "sunrise",
                        iconColor: .orange,
                        title: "Launch at Login",
                        isOn: Binding(
                            get: { appState.launchAtLogin },
                            set: { appState.updateLaunchAtLogin($0) }
                        )
                    )

                    if let hint = appState.launchAtLoginHint {
                        Text(hint)
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 4)
                    }

                    if appState.accessibilityGranted {
                        activitySection
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)

            Divider()
                .padding(.horizontal, 12)

            // Footer
            footer
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
        }
        .frame(width: 300, height: appState.accessibilityGranted ? 420 : 280)
        .onAppear {
            appState.refreshPermission(prompt: false)
        }
    }
}

// MARK: - Components

private extension MenuBarView {

    var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "rectangle.on.rectangle")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.blue)

            Text("Corral")
                .font(.system(size: 14, weight: .bold))

            Spacer()

            HStack(spacing: 5) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 6, height: 6)

                Text(statusLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: Permission Banner

    var permissionBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(.orange)
                Text("Accessibility permission required")
                    .font(.system(size: 12, weight: .medium))
            }

            Text("Corral needs access to watch Finder windows and merge them into tabs.")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                appState.requestAccessibilityPermission()
            } label: {
                Text("Open System Settings")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity)
            }
            .controlSize(.regular)
            .buttonStyle(.borderedProminent)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.orange.opacity(colorScheme == .dark ? 0.1 : 0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.orange.opacity(0.2), lineWidth: 0.5)
        )
    }

    // MARK: Toggle Rows

    func toggleRow(icon: String, iconColor: Color, title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(iconColor)
                .frame(width: 20)

            Text(title)
                .font(.system(size: 13))

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    // MARK: Merge Now

    var mergeNowRow: some View {
        Button {
            appState.mergeNow()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: appState.isMergingNow
                    ? "arrow.triangle.2.circlepath"
                    : "sparkles.rectangle.stack")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 20)

                Text(appState.isMergingNow ? "Merging..." : "Merge Now")
                    .font(.system(size: 13))
                    .foregroundStyle(.primary)

                Spacer()

                Text("⌘M")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(appState.isMergingNow)
    }

    // MARK: Activity

    var activitySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .padding(.horizontal, 12)
                .padding(.vertical, 6)

            HStack {
                Text("Activity")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .textCase(.uppercase)

                Spacer()

                Text(appState.statusText)
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 6)

            if appState.logs.isEmpty {
                Text("Waiting for Finder activity...")
                    .font(.system(size: 11))
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(appState.logs.prefix(6), id: \.self) { entry in
                        Text(entry)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 3)
                    }
                }
            }
        }
    }

    // MARK: Footer

    var footer: some View {
        HStack {
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
            .font(.system(size: 12))
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)

            Spacer()

            Text("v1.0")
                .font(.system(size: 10))
                .foregroundStyle(.quaternary)
        }
    }

    // MARK: Status

    var statusColor: Color {
        if !appState.accessibilityGranted { return .orange }
        return appState.isEnabled ? .green : .gray
    }

    var statusLabel: String {
        if !appState.accessibilityGranted { return "Needs Setup" }
        return appState.isEnabled ? "Active" : "Paused"
    }
}

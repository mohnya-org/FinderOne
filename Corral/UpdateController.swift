import AppKit
import Combine
import Sparkle
import SwiftUI

@MainActor
final class UpdateController: ObservableObject {
    @Published private(set) var canCheckForUpdates = false
    @Published private(set) var automaticallyChecksForUpdates = false
    let isConfigured: Bool
    private let controller: SPUStandardUpdaterController

    init() {
        // Local builds can omit the release signing key; do not start an invalid updater.
        let key = Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey") as? String ?? ""
        isConfigured = Data(base64Encoded: key)?.count == 32
        controller = SPUStandardUpdaterController(
            startingUpdater: false, updaterDelegate: nil, userDriverDelegate: nil
        )
        controller.updater.publisher(for: \.canCheckForUpdates)
            .assign(to: &$canCheckForUpdates)
        controller.updater.publisher(for: \.automaticallyChecksForUpdates)
            .assign(to: &$automaticallyChecksForUpdates)
    }

    func start() {
        guard isConfigured else { return }
        controller.startUpdater()
    }

    func checkForUpdates() {
        NSApp.activate(ignoringOtherApps: true)
        controller.checkForUpdates(nil)
    }

    func setAutomaticallyChecksForUpdates(_ enabled: Bool) {
        controller.updater.automaticallyChecksForUpdates = enabled
    }
}

struct SoftwareUpdateView: View {
    @EnvironmentObject private var updates: UpdateController

    var body: some View {
        VStack(spacing: 2) {
            HStack(spacing: 10) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.blue)
                    .frame(width: 20)

                Text("Automatically check for updates")
                    .font(.system(size: 13))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Toggle("Automatically check for updates", isOn: Binding(
                    get: { updates.automaticallyChecksForUpdates },
                    set: { updates.setAutomaticallyChecksForUpdates($0) }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
                .disabled(!updates.isConfigured)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            Button {
                updates.checkForUpdates()
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.blue)
                        .frame(width: 20)

                    Text("Check for Updates…")
                        .font(.system(size: 13))
                        .foregroundStyle(.primary)

                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!updates.canCheckForUpdates)
            .help(updates.isConfigured ? "Check for a new version" : "Updates are unavailable in this development build")
        }
    }
}

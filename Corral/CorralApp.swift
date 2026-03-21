import SwiftUI

@main
struct CorralApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appDelegate.appState)
        } label: {
            Image(nsImage: MenuBarIconFactory.image(for: appDelegate.appState.menuBarIconState))
        }
        .menuBarExtraStyle(.window)

        Settings {
            EmptyView()
        }
    }
}

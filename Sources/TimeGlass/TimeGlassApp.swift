import SwiftUI
import SwiftData

@main
struct TimeGlassApp: App {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(for: Project.self, TimeEntry.self, Client.self)
        LoginItemManager.registerIfNeeded()
        _ = ToastWindowController.shared
        IdleDetector.shared.activate(with: container.mainContext)
        NotificationManager.shared.requestAuthorizationIfNeeded()
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
        } label: {
            MenuBarLabelView()
        }
        .menuBarExtraStyle(.window)
        .modelContainer(container)
    }
}

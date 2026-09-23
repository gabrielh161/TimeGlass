import SwiftUI
import SwiftData

@main
struct TimeGlassApp: App {
    let container: ModelContainer

    init() {
        container = try! ModelContainer(for: Project.self, TimeEntry.self, Client.self)
        LoginItemManager.registerIfNeeded()
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

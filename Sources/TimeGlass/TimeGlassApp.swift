import SwiftUI

@main
struct TimeGlassApp: App {
    var body: some Scene {
        MenuBarExtra {
            Text("TimeGlass")
        } label: {
            Image(systemName: "timer")
        }
        .menuBarExtraStyle(.window)
    }
}

import ServiceManagement

enum LoginItemManager {
    static func registerIfNeeded() {
        guard SMAppService.mainApp.status == .notRegistered else { return }
        try? SMAppService.mainApp.register()
    }
}

import SwiftUI

/// Lightweight pub/sub bridge so tracking logic (TimeTracker) can trigger a brief visual
/// confirmation without depending on AppKit window management directly. ToastWindowController
/// observes this notification and renders/animates the actual overlay panel.
enum ToastCenter {
    static let didPostToast = Notification.Name("TimeGlass.toast")

    static func post(title: String, systemImage: String, tint: Color) {
        NotificationCenter.default.post(
            name: didPostToast,
            object: nil,
            userInfo: ["title": title, "systemImage": systemImage, "tint": tint]
        )
    }
}

import AppKit
import SwiftUI

/// Owns a single borderless, click-through NSPanel used to show brief start/stop toasts near
/// the top-right of the screen (roughly under the menu bar). Instantiated once at app launch
/// (see TimeGlassApp.init) and driven purely by ToastCenter notifications, so tracking logic
/// never needs to know about AppKit windows.
final class ToastWindowController {
    static let shared = ToastWindowController()

    private var panel: NSPanel?
    private var dismissWorkItem: DispatchWorkItem?

    private init() {
        NotificationCenter.default.addObserver(
            forName: ToastCenter.didPostToast, object: nil, queue: .main
        ) { [weak self] note in
            guard let info = note.userInfo,
                  let title = info["title"] as? String,
                  let systemImage = info["systemImage"] as? String,
                  let tint = info["tint"] as? Color else { return }
            self?.show(title: title, systemImage: systemImage, tint: tint)
        }
    }

    private func show(title: String, systemImage: String, tint: Color) {
        dismissWorkItem?.cancel()

        let size = CGSize(width: 240, height: 46)
        let hosting = NSHostingView(rootView: ToastView(title: title, systemImage: systemImage, tint: tint))
        hosting.frame = CGRect(origin: .zero, size: size)

        let panel: NSPanel
        if let existing = self.panel {
            panel = existing
        } else {
            panel = NSPanel(
                contentRect: CGRect(origin: .zero, size: size),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = true
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            panel.ignoresMouseEvents = true
            self.panel = panel
        }
        panel.contentView = hosting

        if let screenFrame = NSScreen.main?.visibleFrame {
            let x = screenFrame.maxX - size.width - 16
            let y = screenFrame.maxY - size.height - 6
            panel.setFrame(CGRect(x: x, y: y, width: size.width, height: size.height), display: true)
        }

        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.16
            panel.animator().alphaValue = 1
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let panel = self?.panel else { return }
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.25
                panel.animator().alphaValue = 0
            } completionHandler: {
                panel.orderOut(nil)
            }
        }
        dismissWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }
}

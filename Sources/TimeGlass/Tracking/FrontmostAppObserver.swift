import AppKit
import Observation

/// Tracks the name of the frontmost application as a lightweight signal for project
/// suggestions (item 23 of the backlog).
///
/// This is a deliberate fallback rather than the full "automatic project suggestion" ideal:
/// it only observes which app is frontmost, via NSWorkspace.didActivateApplicationNotification
/// - a notification macOS already provides for free, with no special permission required. It
/// does NOT read window titles or document names, which would need the Accessibility
/// permission and per-app UI scripting; that's considerably heavier/more fragile to get right
/// unsupervised. Practical limitation: it can match "Lightroom Classic" being frontmost against
/// a project literally named "Lightroom Classic" (or containing it), but can't tell which
/// client's catalog or document is actually open within it.
@Observable
final class FrontmostAppObserver: NSObject {
    static let shared = FrontmostAppObserver()

    private(set) var frontmostAppName: String?

    private override init() {
        super.init()
        frontmostAppName = NSWorkspace.shared.frontmostApplication?.localizedName
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleActivation),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    @objc private func handleActivation(_ note: Notification) {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
        frontmostAppName = app.localizedName
    }
}

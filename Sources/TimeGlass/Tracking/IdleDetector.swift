import AppKit
import SwiftData

/// Auto-pauses the running timer when the Mac locks or goes to sleep, so tracked time doesn't
/// keep accruing while Gabriel is away from the keyboard.
///
/// Design choice: this listens for actual lock/sleep *events* via NSWorkspace and the
/// DistributedNotificationCenter "screen is locked" notifications, rather than polling IOKit's
/// HID idle time (CGEventSource idle seconds / IOHIDSystem). The event-driven approach needs no
/// polling timer, has no arbitrary "idle threshold" to tune, and reacts to the same trigger the
/// system itself uses to lock the screen - which is what actually matters for "time shouldn't
/// accrue while away". It's a deliberately simple v1: it pauses on lock/sleep, but does not
/// attempt to resume automatically on unlock (that could restart a timer for the wrong project,
/// or restart tracking when Gabriel unlocked just to check something and isn't back at work) -
/// resuming is a conscious action via Start/"Fortsetzen".
@MainActor
final class IdleDetector: NSObject {
    static let shared = IdleDetector()

    private var tracker: TimeTracker?

    private override init() {
        super.init()
        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceCenter.addObserver(self, selector: #selector(pauseIfRunning), name: NSWorkspace.screensDidSleepNotification, object: nil)
        workspaceCenter.addObserver(self, selector: #selector(pauseIfRunning), name: NSWorkspace.sessionDidResignActiveNotification, object: nil)

        let distributed = DistributedNotificationCenter.default()
        distributed.addObserver(self, selector: #selector(pauseIfRunning), name: Notification.Name("com.apple.screenIsLocked"), object: nil)
    }

    /// Must be called once at launch with the app's model context before lock/sleep events can
    /// pause anything.
    func activate(with context: ModelContext) {
        tracker = TimeTracker(context: context)
    }

    @objc private func pauseIfRunning() {
        tracker?.pause()
    }
}

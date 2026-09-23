import AppKit

/// Subtle system-sound feedback on start/pause/stop, toggle-able via AppSettings.soundEnabled.
enum SoundFeedback {
    enum Kind {
        case start, pause, stop

        /// Named system sounds bundled with macOS (Sound > Sound Effects in System Settings),
        /// chosen to be short and unobtrusive rather than jarring.
        var soundName: NSSound.Name {
            switch self {
            case .start: return "Tink"
            case .pause: return "Morse"
            case .stop: return "Pop"
            }
        }
    }

    static func play(_ kind: Kind) {
        guard AppSettings.shared.soundEnabled else { return }
        NSSound(named: kind.soundName)?.play()
    }
}

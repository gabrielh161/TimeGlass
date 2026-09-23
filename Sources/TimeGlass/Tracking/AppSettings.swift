import Foundation
import Observation

/// Central, UserDefaults-backed settings store for TimeGlass. Shared as a singleton and
/// injected into the SwiftUI environment so any view (and the menu bar label) can read/write
/// preferences without threading them through every initializer.
@Observable
final class AppSettings {
    static let shared = AppSettings()

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.dailyGoalHours = Self.readDouble(defaults, Keys.dailyGoalHours, default: 8)
        self.showRemainingTime = defaults.object(forKey: Keys.showRemainingTime) as? Bool ?? false
        self.compactMode = defaults.object(forKey: Keys.compactMode) as? Bool ?? false
        self.soundEnabled = defaults.object(forKey: Keys.soundEnabled) as? Bool ?? true
        self.countdownMode = defaults.object(forKey: Keys.countdownMode) as? Bool ?? false
        self.forgotToStopHours = Self.readDouble(defaults, Keys.forgotToStopHours, default: 3)
        self.morningReminderEnabled = defaults.object(forKey: Keys.morningReminderEnabled) as? Bool ?? true
        self.frontmostAppSuggestionEnabled = defaults.object(forKey: Keys.frontmostAppSuggestionEnabled) as? Bool ?? true
    }

    var dailyGoalHours: Double {
        didSet { defaults.set(dailyGoalHours, forKey: Keys.dailyGoalHours) }
    }

    /// When true, the menu bar label shows time remaining until the daily goal instead of
    /// elapsed time for the running session.
    var showRemainingTime: Bool {
        didSet { defaults.set(showRemainingTime, forKey: Keys.showRemainingTime) }
    }

    /// When true, the menu bar shows only the icon, no text label.
    var compactMode: Bool {
        didSet { defaults.set(compactMode, forKey: Keys.compactMode) }
    }

    var soundEnabled: Bool {
        didSet { defaults.set(soundEnabled, forKey: Keys.soundEnabled) }
    }

    /// When true and the running project has a budget, the header counts down against the
    /// remaining budget instead of counting up.
    var countdownMode: Bool {
        didSet { defaults.set(countdownMode, forKey: Keys.countdownMode) }
    }

    /// Hours a single session may run before a "Vergessen zu stoppen?" notification fires.
    var forgotToStopHours: Double {
        didSet { defaults.set(forgotToStopHours, forKey: Keys.forgotToStopHours) }
    }

    var morningReminderEnabled: Bool {
        didSet { defaults.set(morningReminderEnabled, forKey: Keys.morningReminderEnabled) }
    }

    var frontmostAppSuggestionEnabled: Bool {
        didSet { defaults.set(frontmostAppSuggestionEnabled, forKey: Keys.frontmostAppSuggestionEnabled) }
    }

    private static func readDouble(_ defaults: UserDefaults, _ key: String, default def: Double) -> Double {
        let value = defaults.double(forKey: key)
        return value == 0 ? def : value
    }

    private enum Keys {
        static let dailyGoalHours = "dailyGoalHours"
        static let showRemainingTime = "showRemainingTime"
        static let compactMode = "compactMode"
        static let soundEnabled = "soundEnabled"
        static let countdownMode = "countdownMode"
        static let forgotToStopHours = "forgotToStopHours"
        static let morningReminderEnabled = "morningReminderEnabled"
        static let frontmostAppSuggestionEnabled = "frontmostAppSuggestionEnabled"
    }
}

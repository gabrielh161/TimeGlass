import Foundation

enum DurationFormatting {
    static func format(_ seconds: TimeInterval) -> String {
        let total = max(0, Int(seconds.rounded()))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let secs = total % 60
        return String(format: "%d:%02d:%02d", hours, minutes, secs)
    }

    /// Formats a duration given in hours (e.g. a budget) compactly, e.g. "3,5 h".
    static func formatHours(_ hours: Double) -> String {
        String(format: "%.1f h", hours).replacingOccurrences(of: ".", with: ",")
    }
}

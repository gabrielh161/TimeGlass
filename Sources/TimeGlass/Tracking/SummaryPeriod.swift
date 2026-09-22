import Foundation

enum SummaryPeriod: String, CaseIterable {
    case today
    case week

    func startDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        switch self {
        case .today:
            return calendar.startOfDay(for: now)
        case .week:
            return calendar.dateInterval(of: .weekOfYear, for: now)?.start
                ?? calendar.startOfDay(for: now)
        }
    }
}

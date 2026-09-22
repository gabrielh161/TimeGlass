import XCTest
@testable import TimeGlass

final class SummaryPeriodTests: XCTestCase {
    func testTodayStartIsStartOfDay() {
        let now = Date()
        let calendar = Calendar.current
        XCTAssertEqual(
            SummaryPeriod.today.startDate(now: now, calendar: calendar),
            calendar.startOfDay(for: now)
        )
    }

    func testWeekStartIsOnOrBeforeTodayAndWithinSevenDays() {
        let now = Date()
        let calendar = Calendar.current
        let weekStart = SummaryPeriod.week.startDate(now: now, calendar: calendar)
        XCTAssertLessThanOrEqual(weekStart, calendar.startOfDay(for: now))
        let days = calendar.dateComponents([.day], from: weekStart, to: now).day ?? 99
        XCTAssertLessThan(days, 7)
    }
}

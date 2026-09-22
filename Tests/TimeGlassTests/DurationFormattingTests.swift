import XCTest
@testable import TimeGlass

final class DurationFormattingTests: XCTestCase {
    func testFormatsUnderAnHour() {
        XCTAssertEqual(DurationFormatting.format(1102), "0:18:22")
    }

    func testFormatsOverAnHour() {
        XCTAssertEqual(DurationFormatting.format(8140), "2:15:40")
    }

    func testClampsNegativeToZero() {
        XCTAssertEqual(DurationFormatting.format(-5), "0:00:00")
    }

    func testRoundsToNearestSecond() {
        XCTAssertEqual(DurationFormatting.format(59.6), "0:01:00")
    }
}

import XCTest
import SwiftData
@testable import TimeGlass

@MainActor
final class TimeTrackerTests: XCTestCase {
    var container: ModelContainer!
    var tracker: TimeTracker!

    override func setUpWithError() throws {
        let schema = Schema([Project.self, TimeEntry.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        tracker = TimeTracker(context: container.mainContext)
    }

    func testStartCreatesRunningEntry() {
        let entry = tracker.start(projectNamed: "Website SEO")
        XCTAssertNil(entry.end)
        XCTAssertEqual(entry.project?.name, "Website SEO")
    }

    func testStartingSecondProjectStopsFirst() {
        let base = Date()
        let first = tracker.start(projectNamed: "A", now: base)
        let second = tracker.start(projectNamed: "B", now: base.addingTimeInterval(60))
        XCTAssertEqual(first.end, base.addingTimeInterval(60))
        XCTAssertNil(second.end)
    }

    func testStartingSameNameCaseInsensitiveReusesProject() throws {
        _ = tracker.start(projectNamed: "Buchhaltung")
        tracker.stopActiveEntry()
        _ = tracker.start(projectNamed: "buchhaltung")
        let projects = try container.mainContext.fetch(FetchDescriptor<Project>())
        XCTAssertEqual(projects.count, 1)
    }

    func testDeleteProjectRemovesItsEntries() throws {
        let entry = tracker.start(projectNamed: "Temp")
        let project = try XCTUnwrap(entry.project)
        tracker.stopActiveEntry()
        tracker.delete(project)
        let entries = try container.mainContext.fetch(FetchDescriptor<TimeEntry>())
        XCTAssertTrue(entries.isEmpty)
    }

    func testTotalSecondsSumsWithinRange() throws {
        let base = Date()
        let entry = tracker.start(projectNamed: "X", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(120))
        let project = try XCTUnwrap(entry.project)
        let total = tracker.totalSeconds(
            for: project,
            since: base.addingTimeInterval(-3600),
            now: base.addingTimeInterval(120)
        )
        XCTAssertEqual(total, 120, accuracy: 0.01)
    }

    func testActiveEntryReflectsRunningState() {
        XCTAssertNil(tracker.activeEntry())
        _ = tracker.start(projectNamed: "Y")
        XCTAssertNotNil(tracker.activeEntry())
        tracker.stopActiveEntry()
        XCTAssertNil(tracker.activeEntry())
    }

    func testTotalSecondsClampsUpperBound() throws {
        let base = Date()
        // Create an entry that runs from base to base+600 (10 minutes)
        let entry = tracker.start(projectNamed: "Z", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(600))
        let project = try XCTUnwrap(entry.project)
        // Query with now: base+120 — should only count 120 seconds, not the full 600
        let total = tracker.totalSeconds(
            for: project,
            since: base,
            now: base.addingTimeInterval(120)
        )
        XCTAssertEqual(total, 120, accuracy: 0.01)
    }

    func testRestartCreatesNewRunningEntryForSameProject() throws {
        let base = Date()
        let first = tracker.start(projectNamed: "Restart Me", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(60))
        let project = try XCTUnwrap(first.project)
        tracker.restart(project, now: base.addingTimeInterval(120))
        let active = tracker.activeEntry()
        XCTAssertNotNil(active)
        XCTAssertEqual(active?.project?.name, "Restart Me")
        XCTAssertEqual(active?.start, base.addingTimeInterval(120))
    }

    func testDeletingActiveProjectClearsActiveEntry() throws {
        let entry = tracker.start(projectNamed: "Active Delete")
        let project = try XCTUnwrap(entry.project)
        XCTAssertNotNil(tracker.activeEntry())
        tracker.delete(project)
        XCTAssertNil(tracker.activeEntry())
    }

    func testAtMostOneActiveEntryAfterStartRestartStartSequence() throws {
        let base = Date()
        let first = tracker.start(projectNamed: "One", now: base)
        let firstProject = try XCTUnwrap(first.project)
        tracker.restart(firstProject, now: base.addingTimeInterval(60))
        _ = tracker.start(projectNamed: "Two", now: base.addingTimeInterval(120))
        let descriptor = FetchDescriptor<TimeEntry>(predicate: #Predicate { $0.end == nil })
        let openEntries = try container.mainContext.fetch(descriptor)
        XCTAssertEqual(openEntries.count, 1)
    }
}

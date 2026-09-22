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

    func testEntriesForProjectFiltersBySinceAndSortsNewestFirst() throws {
        let base = Date()
        let entry = tracker.start(projectNamed: "Sessions", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(60))
        let project = try XCTUnwrap(entry.project)
        tracker.restart(project, now: base.addingTimeInterval(3600))
        tracker.stopActiveEntry(now: base.addingTimeInterval(3700))

        let all = tracker.entries(for: project, since: base.addingTimeInterval(-1))
        XCTAssertEqual(all.count, 2)
        XCTAssertEqual(all.first?.start, base.addingTimeInterval(3600))

        let filtered = tracker.entries(for: project, since: base.addingTimeInterval(1800))
        XCTAssertEqual(filtered.count, 1)
    }

    func testUpdateEntryChangesStartAndEnd() throws {
        let base = Date()
        let entry = tracker.start(projectNamed: "Fix Me", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(600))
        let newStart = base.addingTimeInterval(-1800)
        let newEnd = base.addingTimeInterval(-1200)
        let ok = tracker.updateEntry(entry, start: newStart, end: newEnd)
        XCTAssertTrue(ok)
        XCTAssertEqual(entry.start, newStart)
        XCTAssertEqual(entry.end, newEnd)
    }

    func testUpdateEntryRejectsEndBeforeStart() throws {
        let base = Date()
        let entry = tracker.start(projectNamed: "Bad Range", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(600))
        let originalStart = entry.start
        let originalEnd = entry.end
        let ok = tracker.updateEntry(entry, start: base, end: base.addingTimeInterval(-100))
        XCTAssertFalse(ok)
        XCTAssertEqual(entry.start, originalStart)
        XCTAssertEqual(entry.end, originalEnd)
    }

    func testUpdateEntryCanAdjustActiveEntryStart() throws {
        let base = Date()
        let entry = tracker.start(projectNamed: "Active Fix", now: base)
        let newStart = base.addingTimeInterval(-300)
        let ok = tracker.updateEntry(entry, start: newStart, end: nil)
        XCTAssertTrue(ok)
        XCTAssertEqual(entry.start, newStart)
        XCTAssertNil(entry.end)
    }

    func testUpdateEntryRejectsReopeningClosedEntry() throws {
        let base = Date()
        let entry = tracker.start(projectNamed: "No Reopen", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(600))
        let ok = tracker.updateEntry(entry, start: base, end: nil)
        XCTAssertFalse(ok)
        XCTAssertNotNil(entry.end)
    }

    func testAddManualEntryCreatesClosedEntry() throws {
        let entry = tracker.start(projectNamed: "Manual")
        let project = try XCTUnwrap(entry.project)
        tracker.stopActiveEntry()
        let start = Date().addingTimeInterval(-7200)
        let end = Date().addingTimeInterval(-3600)
        let ok = tracker.addManualEntry(to: project, start: start, end: end)
        XCTAssertTrue(ok)
        let entries = tracker.entries(for: project, since: start.addingTimeInterval(-1))
        XCTAssertTrue(entries.contains { $0.start == start && $0.end == end })
    }

    func testAddManualEntryRejectsEndBeforeStart() throws {
        let entry = tracker.start(projectNamed: "Manual Bad")
        let project = try XCTUnwrap(entry.project)
        tracker.stopActiveEntry()
        let ok = tracker.addManualEntry(to: project, start: Date(), end: Date().addingTimeInterval(-100))
        XCTAssertFalse(ok)
    }

    func testDeleteEntryRemovesJustThatEntry() throws {
        let base = Date()
        let entry = tracker.start(projectNamed: "Delete One", now: base)
        tracker.stopActiveEntry(now: base.addingTimeInterval(60))
        let project = try XCTUnwrap(entry.project)
        tracker.restart(project, now: base.addingTimeInterval(120))
        tracker.stopActiveEntry(now: base.addingTimeInterval(180))
        XCTAssertEqual(tracker.entries(for: project, since: base.addingTimeInterval(-1)).count, 2)
        tracker.deleteEntry(entry)
        XCTAssertEqual(tracker.entries(for: project, since: base.addingTimeInterval(-1)).count, 1)
    }
}

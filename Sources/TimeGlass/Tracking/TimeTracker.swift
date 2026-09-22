import Foundation
import SwiftData

@MainActor
final class TimeTracker {
    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    func activeEntry() -> TimeEntry? {
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate { $0.end == nil }
        )
        return try? context.fetch(descriptor).first
    }

    @discardableResult
    func start(projectNamed rawName: String, now: Date = .now) -> TimeEntry {
        let name = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        stopActiveEntry(now: now)
        let project = findProject(named: name) ?? {
            let created = Project(name: name, createdAt: now)
            context.insert(created)
            return created
        }()
        let entry = TimeEntry(project: project, start: now)
        context.insert(entry)
        try? context.save()
        return entry
    }

    func stopActiveEntry(now: Date = .now) {
        guard let entry = activeEntry() else { return }
        entry.end = now
        try? context.save()
    }

    func restart(_ project: Project, now: Date = .now) {
        start(projectNamed: project.name, now: now)
    }

    func delete(_ project: Project) {
        context.delete(project)
        try? context.save()
    }

    func totalSeconds(for project: Project, since start: Date, now: Date = .now) -> TimeInterval {
        project.entries.reduce(0) { partial, entry in
            let end = min(entry.end ?? now, now)
            let clampedStart = max(entry.start, start)
            guard end > clampedStart else { return partial }
            return partial + end.timeIntervalSince(clampedStart)
        }
    }

    private func findProject(named name: String) -> Project? {
        let all = (try? context.fetch(FetchDescriptor<Project>())) ?? []
        return all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }
}

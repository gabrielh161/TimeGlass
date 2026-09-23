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
        ToastCenter.post(title: "\(project.name) gestartet", systemImage: "play.fill", tint: ProjectColor.color(for: project))
        SoundFeedback.play(.start)
        NotificationManager.shared.scheduleForgotToStop(projectName: project.name, hours: AppSettings.shared.forgotToStopHours)
        return entry
    }

    func stopActiveEntry(now: Date = .now) {
        guard let entry = activeEntry() else { return }
        entry.end = now
        try? context.save()
        NotificationManager.shared.cancelForgotToStop()
        if let project = entry.project {
            ToastCenter.post(title: "\(project.name) gestoppt", systemImage: "stop.fill", tint: ProjectColor.color(for: project))
            SoundFeedback.play(.stop)
        }
    }

    /// Pauses the running session: a short interruption within the same logical work block,
    /// represented simply as closing the current entry (identical storage-wise to stopping).
    /// The distinction is purely UX: pausing is expected to be resumed shortly via
    /// `mostRecentProject()` / the "Fortsetzen" quick action, rather than being a deliberate
    /// end of work. No schema change needed - the existing start/end model already supports
    /// this once "resume" is just starting a fresh entry for the same project.
    func pause(now: Date = .now) {
        guard let entry = activeEntry() else { return }
        let project = entry.project
        entry.end = now
        try? context.save()
        NotificationManager.shared.cancelForgotToStop()
        if let project {
            ToastCenter.post(title: "\(project.name) pausiert", systemImage: "pause.fill", tint: ProjectColor.color(for: project))
            SoundFeedback.play(.pause)
        }
    }

    /// The project of the most recently started entry, regardless of whether it's still
    /// running, was paused, or was stopped - used for the "Fortsetzen" quick action.
    func mostRecentProject() -> Project? {
        var descriptor = FetchDescriptor<TimeEntry>(sortBy: [SortDescriptor(\.start, order: .reverse)])
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first?.project
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

    /// Sum of tracked seconds across all given projects since `start` - used for the daily
    /// goal concept (menu bar progress, remaining-time label, progress ring, etc.).
    func totalSecondsAcrossProjects(_ projects: [Project], since start: Date, now: Date = .now) -> TimeInterval {
        projects.reduce(0) { $0 + totalSeconds(for: $1, since: start, now: now) }
    }

    // MARK: - Insights

    /// Total seconds per calendar day across the given projects, oldest first, for the last
    /// `days` days including today. Powers the trend chart.
    func dailyTotals(for projects: [Project], days: Int, now: Date = .now, calendar: Calendar = .current) -> [(date: Date, seconds: TimeInterval)] {
        let todayStart = calendar.startOfDay(for: now)
        return (0..<days).reversed().compactMap { offset -> (Date, TimeInterval)? in
            guard let dayStart = calendar.date(byAdding: .day, value: -offset, to: todayStart),
                  let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart) else { return nil }
            let seconds = projects.reduce(0.0) { partial, project in
                partial + project.entries.reduce(0.0) { inner, entry in
                    let end = min(entry.end ?? now, min(dayEnd, now))
                    let start = max(entry.start, dayStart)
                    guard end > start else { return inner }
                    return inner + end.timeIntervalSince(start)
                }
            }
            return (dayStart, seconds)
        }
    }

    /// Average length of completed (non-running) sessions across the given projects.
    func averageSessionLength(for projects: [Project]) -> TimeInterval {
        let completed = projects.flatMap(\.entries).compactMap { entry -> TimeInterval? in
            guard let end = entry.end else { return nil }
            return end.timeIntervalSince(entry.start)
        }
        guard !completed.isEmpty else { return 0 }
        return completed.reduce(0, +) / Double(completed.count)
    }

    /// The most common rough time-of-day bucket sessions were started in, e.g. "Nachmittag".
    func mostCommonStartBucket(for projects: [Project], calendar: Calendar = .current) -> String? {
        let buckets = projects.flatMap(\.entries).map { entry -> String in
            switch calendar.component(.hour, from: entry.start) {
            case 5..<12: return "Vormittag"
            case 12..<17: return "Nachmittag"
            case 17..<22: return "Abend"
            default: return "Nacht"
            }
        }
        guard !buckets.isEmpty else { return nil }
        let counts = Dictionary(grouping: buckets, by: { $0 }).mapValues(\.count)
        return counts.max(by: { $0.value < $1.value })?.key
    }

    /// Hours + revenue (via each project's hourlyRate) per client since `start`.
    func clientTotals(clients: [Client], since start: Date, now: Date = .now) -> [(client: Client, seconds: TimeInterval, revenue: Double)] {
        clients.map { client in
            var seconds: TimeInterval = 0
            var revenue: Double = 0
            for project in client.projects {
                let projectSeconds = totalSeconds(for: project, since: start, now: now)
                seconds += projectSeconds
                if let rate = project.hourlyRate {
                    revenue += (projectSeconds / 3600) * rate
                }
            }
            return (client, seconds, revenue)
        }
        .sorted { $0.seconds > $1.seconds }
    }

    func entries(for project: Project, since start: Date) -> [TimeEntry] {
        project.entries
            .filter { $0.start >= start }
            .sorted { $0.start > $1.start }
    }

    @discardableResult
    func updateEntry(_ entry: TimeEntry, start: Date, end: Date?) -> Bool {
        if let end, end <= start { return false }
        if end == nil, entry.end != nil { return false }
        entry.start = start
        entry.end = end
        try? context.save()
        return true
    }

    @discardableResult
    func addManualEntry(to project: Project, start: Date, end: Date) -> Bool {
        guard end > start else { return false }
        let entry = TimeEntry(project: project, start: start, end: end)
        context.insert(entry)
        try? context.save()
        return true
    }

    func deleteEntry(_ entry: TimeEntry) {
        context.delete(entry)
        try? context.save()
    }

    private func findProject(named name: String) -> Project? {
        let all = (try? context.fetch(FetchDescriptor<Project>())) ?? []
        return all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    // MARK: - Clients

    func allClients() -> [Client] {
        let descriptor = FetchDescriptor<Client>(sortBy: [SortDescriptor(\.name)])
        return (try? context.fetch(descriptor)) ?? []
    }

    private func findClient(named name: String) -> Client? {
        let all = (try? context.fetch(FetchDescriptor<Client>())) ?? []
        return all.first { $0.name.caseInsensitiveCompare(name) == .orderedSame }
    }

    /// Assigns the project to a client, finding an existing client by name (case-insensitive)
    /// or creating a new one. Passing nil or an empty/whitespace-only name clears the client.
    func setClient(for project: Project, named rawName: String?, now: Date = .now) {
        let trimmed = rawName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            project.client = nil
            try? context.save()
            return
        }
        let client = findClient(named: trimmed) ?? {
            let created = Client(name: trimmed, createdAt: now)
            context.insert(created)
            return created
        }()
        project.client = client
        try? context.save()
    }

    // MARK: - Project attributes

    func updateProjectAttributes(_ project: Project, hourlyRate: Double?, tags: [String], budgetHours: Double?) {
        project.hourlyRate = hourlyRate
        project.tags = tags
        project.budgetHours = budgetHours
        try? context.save()
    }

    // MARK: - Notes

    func updateNote(_ entry: TimeEntry, note: String?) {
        let trimmed = note?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        entry.note = trimmed.isEmpty ? nil : trimmed
        try? context.save()
    }
}

import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var createdAt: Date

    /// Optional hourly billing rate for this project, e.g. for client revenue reporting.
    var hourlyRate: Double?

    /// Simple free-form tags (e.g. "Kundenarbeit", "Admin"), edited as a comma-separated list.
    var tags: [String] = []

    /// Optional budget in hours; UI can warn when tracked time exceeds it.
    var budgetHours: Double?

    @Relationship(deleteRule: .cascade, inverse: \TimeEntry.project)
    var entries: [TimeEntry] = []

    /// A project belongs to at most one client. Existing projects default to nil (no client).
    @Relationship(deleteRule: .nullify)
    var client: Client?

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}

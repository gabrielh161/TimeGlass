import Foundation
import SwiftData

@Model
final class TimeEntry {
    var start: Date
    var end: Date?
    var project: Project?

    init(project: Project, start: Date = .now, end: Date? = nil) {
        self.project = project
        self.start = start
        self.end = end
    }
}

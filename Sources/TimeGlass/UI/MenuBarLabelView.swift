import SwiftUI
import SwiftData

struct MenuBarLabelView: View {
    @Query(filter: #Predicate<TimeEntry> { $0.end == nil })
    private var activeEntries: [TimeEntry]

    var body: some View {
        if let entry = activeEntries.first, let project = entry.project {
            TimelineView(.periodic(from: entry.start, by: 1)) { context in
                Text("\(project.name) · \(DurationFormatting.format(context.date.timeIntervalSince(entry.start)))")
            }
        } else {
            Image(systemName: "timer")
        }
    }
}

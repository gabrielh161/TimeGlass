import SwiftUI

struct SummaryView: View {
    let tracker: TimeTracker
    let projects: [Project]
    @State private var period: SummaryPeriod = .today

    private var rows: [(project: Project, seconds: TimeInterval)] {
        let start = period.startDate()
        return projects
            .map { ($0, tracker.totalSeconds(for: $0, since: start)) }
            .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Summe")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.secondary)
                Spacer()
                Picker("Zeitraum", selection: $period) {
                    Text("Heute").tag(SummaryPeriod.today)
                    Text("Woche").tag(SummaryPeriod.week)
                }
                .labelsHidden()
                .pickerStyle(.segmented)
                .frame(width: 140)
            }

            let maxSeconds = max(rows.map(\.seconds).max() ?? 1, 1)
            ForEach(rows, id: \.project.id) { row in
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(row.project.name).font(.callout)
                        Spacer()
                        Text(DurationFormatting.format(row.seconds))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }
                    GeometryReader { geometry in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(.tint)
                            .frame(width: geometry.size.width * max(row.seconds / maxSeconds, 0.03), height: 5)
                    }
                    .frame(height: 5)
                }
            }
        }
    }
}

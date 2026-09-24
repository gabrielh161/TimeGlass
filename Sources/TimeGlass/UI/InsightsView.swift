import SwiftUI
import Charts

/// Consolidated reporting sheet: trend chart, client comparison and a few self-insights
/// (items 24/27/28), grouped into one sheet with a segmented switch rather than three
/// separate entry points cluttering the popover footer.
struct InsightsView: View {
    let tracker: TimeTracker
    let projects: [Project]
    let onDone: () -> Void

    private enum Tab: String, CaseIterable {
        case trend = "Trend"
        case clients = "Kunden"
        case stats = "Statistik"
    }

    @State private var tab: Tab = .trend

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Einblicke").font(.headline)
                Spacer()
                Button("Fertig") { onDone() }
                    .buttonStyle(.borderless)
            }

            Picker("Ansicht", selection: $tab) {
                ForEach(Tab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            switch tab {
            case .trend:
                TrendChartView(tracker: tracker, projects: projects)
            case .clients:
                ClientComparisonView(tracker: tracker)
            case .stats:
                SelfInsightsView(tracker: tracker, projects: projects)
            }
        }
        .padding(18)
        .frame(width: 340)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20))
    }
}

/// Item 24: small bar chart of hours per day over the last 7 or 30 days.
private struct TrendChartView: View {
    let tracker: TimeTracker
    let projects: [Project]
    @State private var days: Int = 7

    private var totals: [(date: Date, seconds: TimeInterval)] {
        tracker.dailyTotals(for: projects, days: days)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Zeitraum", selection: $days) {
                Text("7 Tage").tag(7)
                Text("30 Tage").tag(30)
            }
            .labelsHidden()
            .pickerStyle(.segmented)

            if totals.allSatisfy({ $0.seconds == 0 }) {
                Text("Noch keine Daten in diesem Zeitraum.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Chart(totals, id: \.date) { entry in
                    BarMark(
                        x: .value("Tag", entry.date, unit: .day),
                        y: .value("Stunden", entry.seconds / 3600)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: days > 7 ? 5 : 1)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.defaultDigits))
                    }
                }
            }
        }
    }
}

/// Item 27: hours + revenue per client, for the current month.
private struct ClientComparisonView: View {
    let tracker: TimeTracker

    private var rows: [(client: Client, seconds: TimeInterval, revenue: Double)] {
        let monthStart = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
        return tracker.clientTotals(clients: tracker.allClients(), since: monthStart)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Diesen Monat").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            if rows.isEmpty {
                Text("Noch keine Kunden angelegt. Kunde lässt sich beim Projekt-Bearbeiten (Stift-Icon) setzen.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rows, id: \.client.id) { row in
                    HStack {
                        Text(row.client.name).font(.callout)
                        Spacer()
                        Text(DurationFormatting.format(row.seconds))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        if row.revenue > 0 {
                            Text("· \(row.revenue, format: .currency(code: "EUR"))")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .font(.caption)
                }
            }
        }
    }
}

/// Item 28: a couple of simple self-insight stats.
private struct SelfInsightsView: View {
    let tracker: TimeTracker
    let projects: [Project]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            let avg = tracker.averageSessionLength(for: projects)
            let bucket = tracker.mostCommonStartBucket(for: projects)

            statRow(title: "Durchschnittliche Sitzungslänge", value: avg > 0 ? DurationFormatting.format(avg) : "–")
            statRow(title: "Meist aktive Tageszeit", value: bucket ?? "–")
        }
    }

    private func statRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.callout.weight(.semibold))
        }
    }
}

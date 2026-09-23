import SwiftUI

/// Shows a formatted date/time as plain text; double-click reveals a date picker to change it.
struct EditableTimeText: View {
    let value: Date
    let tint: Color
    let onCommit: (Date) -> Void

    @State private var isEditing = false
    @State private var draft: Date = .now

    var body: some View {
        if isEditing {
            HStack(spacing: 4) {
                DatePicker("", selection: $draft, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                Button {
                    onCommit(draft)
                    isEditing = false
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(tint)
            }
        } else {
            Text(value, format: .dateTime.day().month().hour().minute())
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    draft = value
                    isEditing = true
                }
        }
    }
}

/// Shows the live elapsed duration since `start`; double-click reveals a date picker to
/// correct the start time (and therefore the elapsed duration) of the running entry.
struct EditableElapsedTimeText: View {
    let start: Date
    let tint: Color
    let onCommit: (Date) -> Void

    @State private var isEditing = false
    @State private var draft: Date = .now

    var body: some View {
        if isEditing {
            HStack(spacing: 6) {
                DatePicker("", selection: $draft, displayedComponents: [.date, .hourAndMinute])
                    .labelsHidden()
                Button {
                    onCommit(draft)
                    isEditing = false
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(tint)
            }
        } else {
            TimelineView(.periodic(from: start, by: 1)) { context in
                Text(DurationFormatting.format(context.date.timeIntervalSince(start)))
                    .font(.system(.title2, design: .monospaced))
                    .monospacedDigit()
            }
            .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                draft = start
                isEditing = true
            }
        }
    }
}

/// Shows an optional free-text note; double-click (or tapping the placeholder) reveals a text
/// field to edit it. An empty note commits as nil.
struct EditableNoteText: View {
    let note: String?
    let tint: Color
    let onCommit: (String?) -> Void

    @State private var isEditing = false
    @State private var draft: String = ""

    var body: some View {
        if isEditing {
            HStack(spacing: 4) {
                TextField("Notiz…", text: $draft)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption2)
                    .onSubmit(commit)
                Button {
                    commit()
                } label: {
                    Image(systemName: "checkmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .foregroundStyle(tint)
            }
        } else {
            Text(note?.isEmpty == false ? note! : "+ Notiz")
                .font(.caption2)
                .foregroundStyle(note?.isEmpty == false ? .secondary : .tertiary)
                .lineLimit(1)
                .contentShape(Rectangle())
                .onTapGesture(count: 2) {
                    draft = note ?? ""
                    isEditing = true
                }
        }
    }

    private func commit() {
        onCommit(draft.trimmingCharacters(in: .whitespacesAndNewlines))
        isEditing = false
    }
}

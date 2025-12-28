import SwiftUI

struct StarPreviewDraft: Equatable {
    enum Field {
        case situation
        case task
        case action
        case result
    }
    
    var situation: String
    var task: String
    var action: String
    var result: String

    static let empty = StarPreviewDraft(situation: "", task: "", action: "", result: "")

    static func from(scannedText: String) -> StarPreviewDraft {
        let lines = scannedText
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        var currentField: Field?
        var buffers: [Field: [String]] = [:]

        for line in lines {
            if let match = matchHeading(in: line) {
                currentField = match.field
                if !match.remaining.isEmpty {
                    buffers[match.field, default: []].append(match.remaining)
                }
                continue
            }

            if let currentField {
                buffers[currentField, default: []].append(line)
            }
        }

        let situation = buffers[.situation]?.joined(separator: "\n") ?? ""
        let task = buffers[.task]?.joined(separator: "\n") ?? ""
        let action = buffers[.action]?.joined(separator: "\n") ?? ""
        let result = buffers[.result]?.joined(separator: "\n") ?? ""

        if [situation, task, action, result].allSatisfy({ $0.isEmpty }) {
            return StarPreviewDraft(situation: scannedText, task: "", action: "", result: "")
        }

        return StarPreviewDraft(situation: situation, task: task, action: action, result: result)
    }

    private static func matchHeading(in line: String) -> (field: Field, remaining: String)? {
        let lowered = line.lowercased()

        let headings: [(String, Field)] = [
            ("situation", .situation),
            ("task", .task),
            ("action", .action),
            ("result", .result)
        ]

        for (label, field) in headings {
            if lowered.hasPrefix(label) {
                let remainder = line.dropFirst(label.count)
                let trimmed = remainder.trimmingCharacters(in: CharacterSet(charactersIn: ":- "))
                return (field, trimmed)
            }

            if lowered.hasPrefix("\(label):") {
                let remainder = line.dropFirst(label.count + 1)
                let trimmed = remainder.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
                return (field, trimmed)
            }
        }

        return nil
    }
}

struct StarPreviewInsertView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var draft: StarPreviewDraft
    let onInsert: (StarPreviewDraft) -> Void

    init(draft: StarPreviewDraft, onInsert: @escaping (StarPreviewDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onInsert = onInsert
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("STAR Preview")
                        .font(.title2).bold()
                        .foregroundStyle(Color.ink900)

                    StarPreviewEditor(label: "Situation", text: $draft.situation)
                    StarPreviewEditor(label: "Task", text: $draft.task)
                    StarPreviewEditor(label: "Action", text: $draft.action)
                    StarPreviewEditor(label: "Result", text: $draft.result)

                    Button(action: {
                        onInsert(draft)
                        dismiss()
                    }) {
                        Label("Insert into Story", systemImage: "checkmark")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 40)
            }
            .navigationTitle("Assist STAR")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct StarPreviewEditor: View {
    let label: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.headline)
                .foregroundStyle(Color.ink900)

            TextEditor(text: $text)
                .frame(minHeight: 100)
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.surfaceWhite))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.ink200, lineWidth: 1)
                )
        }
    }
}

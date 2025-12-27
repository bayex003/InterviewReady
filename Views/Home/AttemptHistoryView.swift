import SwiftUI

struct AttemptHistoryView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Recent Attempts") {
                    // Placeholder rows; replace with real data when available
                    ForEach(0..<5, id: \.self) { idx in
                        HStack {
                            Image(systemName: "waveform")
                                .foregroundStyle(.blue)
                            VStack(alignment: .leading) {
                                Text("Attempt #\(idx + 1)")
                                    .font(.headline)
                                Text("Placeholder details about the practice attempt")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("Attempt History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    AttemptHistoryView()
}

import SwiftUI

struct ScanReviewView: View {
    let scannedText: String
    let onAssistSTAR: () -> Void
    let onRawNotes: () -> Void
    let onManual: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Review scan")
                        .font(.title2.bold())
                        .foregroundStyle(Color.ink900)

                    CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Scanned Text")
                                .font(.headline)
                                .foregroundStyle(Color.ink900)

                            Text(scannedText.isEmpty ? "(No scanned text)" : scannedText)
                                .font(.subheadline)
                                .foregroundStyle(scannedText.isEmpty ? Color.ink400 : Color.ink600)
                        }
                    }

                    VStack(spacing: 12) {
                        PrimaryCTAButton(title: "Assist STAR", systemImage: "sparkles") {
                            onAssistSTAR()
                        }

                        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                            Button {
                                onRawNotes()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Raw Notes")
                                            .font(.headline)
                                            .foregroundStyle(Color.ink900)

                                        Text("Insert the scan into your notes")
                                            .font(.caption)
                                            .foregroundStyle(Color.ink500)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Color.ink400)
                                }
                            }
                            .buttonStyle(.plain)
                        }

                        CardContainer(backgroundColor: Color.surfaceWhite, cornerRadius: 18, showShadow: false) {
                            Button {
                                onManual()
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text("Manual")
                                            .font(.headline)
                                            .foregroundStyle(Color.ink900)

                                        Text("Insert into a draft area to edit")
                                            .font(.caption)
                                            .foregroundStyle(Color.ink500)
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(Color.ink400)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .safeAreaPadding(.bottom, 40)
            }
            .navigationTitle("Scan Review")
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

import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var isWorking = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackgroundView()

                VStack(spacing: 16) {
                    Text("InterviewReady Pro")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.ink900)

                    Text("Unlock lifetime access to Pro features.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink600)
                        .multilineTextAlignment(.center)

                    VStack(alignment: .leading, spacing: 12) {
                        BenefitRow(icon: "square.and.arrow.up", text: "Export All Data (PDF/TXT/Share)")
                        BenefitRow(icon: "clock.arrow.circlepath", text: "Attempt History (see practise attempts)")
                        BenefitRow(icon: "doc.text.viewfinder", text: "Scan Notes into Moments (OCR)")
                        BenefitRow(icon: "icloud", text: "iCloud Sync (backup + multi-device)")
                    }

                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(Color.ink600)
                    }

                    Button {
                        Task { await unlock() }
                    } label: {
                        Text(isWorking ? "Processing…" : "Unlock Pro")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isWorking)

                    Button(isWorking ? "Restoring…" : "Restore Purchases") {
                        Task { await restore() }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isWorking)

                    Spacer()

                    Text("One-time purchase. No subscription.")
                        .font(.caption)
                        .foregroundStyle(Color.ink600)
                }
                .padding()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    @MainActor
    private func unlock() async {
        message = nil
        isWorking = true
        await purchaseManager.purchase()
        isWorking = false

        if purchaseManager.isPro {
            dismiss()
        } else {
            message = "Purchase not completed."
        }
    }

    @MainActor
    private func restore() async {
        message = nil
        isWorking = true
        await purchaseManager.restore()
        isWorking = false

        if purchaseManager.isPro {
            dismiss()
        } else {
            message = "No purchases found to restore."
        }
    }
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.sage500)
                .frame(width: 22)

            Text(text)
                .foregroundStyle(Color.ink900)

            Spacer()
        }
        .font(.subheadline)
    }
}

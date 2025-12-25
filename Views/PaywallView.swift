import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var isProcessing = false

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

                    Button {
                        isProcessing = true
                        Task {
                            await purchaseManager.purchase()
                            isProcessing = false
                        }
                    } label: {
                        Text(isProcessing ? "Processing…" : "Unlock Pro")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isProcessing)

                    Button("Restore Purchases") {
                        isProcessing = true
                        Task {
                            await purchaseManager.restore()
                            isProcessing = false
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(isProcessing)

                    Spacer()
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
}

#Preview {
    PaywallView()
        .environmentObject(PurchaseManager())
}

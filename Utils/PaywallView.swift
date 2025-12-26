import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var isWorking = false
    @State private var message: String?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cream50.ignoresSafeArea()

                VStack(alignment: .leading, spacing: 16) {
                    header

                    benefits

                    if let message {
                        Text(message)
                            .font(.caption)
                            .foregroundStyle(Color.ink600)
                            .padding(.top, 4)
                    }

                    Spacer()

                    primaryButton
                    secondaryButton

                    Text("One-time purchase. No subscription.")
                        .font(.caption)
                        .foregroundStyle(Color.ink600)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.ink900)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("InterviewReady Pro")
                .font(.title2.bold())
                .foregroundStyle(Color.ink900)

            Text("Unlock lifetime access to Pro features.")
                .font(.subheadline)
                .foregroundStyle(Color.ink600)
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            BenefitRow(icon: "square.and.arrow.up", text: "Export your interview pack", iconColor: Color.sage500)
            BenefitRow(icon: "clock.arrow.circlepath", text: "Practice history & progress tracking", iconColor: Color.sage500)
            BenefitRow(icon: "icloud", text: "iCloud sync & backup", iconColor: Color.sage500)
            BenefitRow(icon: "doc.text.viewfinder", text: "Scan notes into Stories", iconColor: Color.sage500)
        }
        .padding()
        .background(Color.surfaceWhite)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }

    private var primaryButton: some View {
        Button {
            Task { await unlock() }
        } label: {
            Text(isWorking ? "Processing…" : "Unlock Pro (One-time)")
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.sage500)
                .foregroundColor(.white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
    }

    private var secondaryButton: some View {
        Button {
            Task { await restore() }
        } label: {
            Text(isWorking ? "Restoring…" : "Restore Purchase")
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.surfaceWhite)
                .foregroundStyle(Color.ink900)
                .overlay(Capsule().strokeBorder(Color.ink200, lineWidth: 1))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isWorking)
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

private struct BenefitRow: View {
    let icon: String
    let text: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .frame(width: 22)

            Text(text)
                .foregroundStyle(Color.ink900)

            Spacer()
        }
        .font(.subheadline)
    }
}

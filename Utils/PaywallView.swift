import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @Environment(\.dismiss) private var dismiss

    @State private var isWorking = false
    @State private var message: String?

    // Price display
    @State private var priceText: String? = nil

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
                    tertiaryButton

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
            .task {
                await loadPrice()
            }
            .onChange(of: purchaseManager.isPro) { _, newValue in
                if newValue { dismiss() }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("InterviewReady Pro")
                .font(.title2.bold())
                .foregroundStyle(Color.ink900)

            Text("Make every practise round count with Pro features.")
                .font(.subheadline)
                .foregroundStyle(Color.ink600)

            if let priceText {
                Text("Price: \(priceText)")
                    .font(.caption)
                    .foregroundStyle(Color.ink600)
                    .padding(.top, 2)
            }
        }
    }

    private var benefits: some View {
        VStack(alignment: .leading, spacing: 12) {
            BenefitRow(icon: "clock.arrow.circlepath", text: "Unlimited answer history", iconColor: Color.sage500)
            BenefitRow(icon: "square.and.arrow.up", text: "Export your data (CSV + raw text)", iconColor: Color.sage500)
            BenefitRow(icon: "list.bullet.rectangle", text: "Review Mode for saved answers", iconColor: Color.sage500)
            BenefitRow(icon: "doc.text.viewfinder", text: "Scan notes into stories", iconColor: Color.sage500)
            BenefitRow(icon: "questionmark.circle", text: "Unlimited custom questions", iconColor: Color.sage500)
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
            HStack(spacing: 10) {
                if isWorking {
                    ProgressView()
                        .tint(.white)
                }
                Text(isWorking ? "Processing…" : primaryTitle)
            }
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

    private var primaryTitle: String {
        if let priceText {
            return "Start Pro (\(priceText))"
        }
        return "Start Pro (One-time)"
    }

    private var secondaryButton: some View {
        Button {
            Task { await restore() }
        } label: {
            HStack(spacing: 10) {
                if isWorking {
                    ProgressView()
                        .tint(Color.ink900)
                }
                Text(isWorking ? "Restoring…" : "Restore purchases")
            }
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

    private var tertiaryButton: some View {
        Button("Not now") {
            dismiss()
        }
        .font(.subheadline.weight(.semibold))
        .foregroundStyle(Color.ink600)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
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

        #if targetEnvironment(simulator)
        // Simulator often triggers sign-in prompts and isn’t a reliable restore environment.
        await purchaseManager.restore()
        isWorking = false
        if purchaseManager.isPro {
            dismiss()
        } else {
            message = "Restore on Simulator can be unreliable. Try on a physical iPhone (or use a Sandbox tester)."
        }
        #else
        await purchaseManager.restore()
        isWorking = false
        if purchaseManager.isPro {
            dismiss()
        } else {
            message = "No purchases found to restore."
        }
        #endif
    }

    // MARK: - Price

    @MainActor
    private func loadPrice() async {
        do {
            let products = try await Product.products(for: [PurchaseManager.productId])
            if let product = products.first {
                priceText = product.displayPrice
            }
        } catch {
            // Don’t show an error; keep it calm.
            priceText = nil
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

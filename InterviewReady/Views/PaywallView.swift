import SwiftUI

struct PaywallView: View {
    @EnvironmentObject private var proManager: ProAccessManager
    @Environment(\._isProUnlocked) private var isProUnlocked
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Unlock InterviewReady Pro")
                    .font(.system(.title2, design: .rounded).bold())
                Text("Access all role packs, richer examples, and unlimited prep.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.75))
            }
            .padding()
            .background(Color.white.opacity(0.06))
            .cornerRadius(18)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(text: "Access to all role packs")
                featureRow(text: "Unlimited saved answers and STAR stories")
                featureRow(text: "Extra example answers")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.white.opacity(0.05))
            .cornerRadius(18)

            if isProUnlocked {
                TagChipView(text: "Already unlocked", color: .irMint)
            }

            PrimaryButton(title: "Simulate Unlock Pro (Dev Mode)") {
                proManager.unlockPro()
            }

            SecondaryButton(title: "Maybe later") {
                dismiss()
            }

            Spacer()
        }
        .padding()
        .background(Color.irBackground.ignoresSafeArea())
        .navigationTitle("Pro")
    }

    private func featureRow(text: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.irMint)
            Text(text)
                .foregroundColor(.white)
        }
    }
}

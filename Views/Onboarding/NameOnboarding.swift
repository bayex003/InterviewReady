import SwiftUI

private struct NameOnboardingPage: View {
    @Binding var userName: String
    @FocusState.Binding var isFocused: Bool
    let keyboardHeight: CGFloat

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {

                Spacer(minLength: 8)

                // Smaller, more polished hero block
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.sage100.opacity(0.45))
                    .frame(height: 160)
                    .overlay(
                        Circle()
                            .fill(Color.surfaceWhite)
                            .frame(width: 42, height: 42)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(Color.sage500)
                            )
                    )
                    .padding(.horizontal, 6)

                VStack(spacing: 8) {
                    Text("Personalise")
                        .font(.title2.bold())
                        .foregroundStyle(Color.ink900)

                    Text("What should we call you? This is optional.")
                        .font(.subheadline)
                        .foregroundStyle(Color.ink600)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 22)
                }
                .padding(.top, 6)

                TextField("Your name (optional)", text: $userName)
                    .textInputAutocapitalization(.words)
                    .submitLabel(.done)
                    .focused($isFocused)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 14)
                    .background(Color.surfaceWhite)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.ink200, lineWidth: 1)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 6)

                // Give breathing room so keyboard doesn’t feel like it crushes the layout
                Spacer(minLength: 140)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
        }
        .scrollDismissesKeyboard(.interactively)
        .contentShape(Rectangle())
        .onTapGesture { isFocused = false }
    }
}

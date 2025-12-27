import SwiftUI

struct PrimaryCTAButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(
        title: String,
        systemImage: String? = "chevron.right",
        action: @escaping () -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .fontWeight(.bold)

                Spacer()

                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color.sage500)
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

import SwiftUI

struct FloatingAddButton: View {
    var action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 56)
                .background(Color.sage500)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.18), radius: 14, x: 0, y: 8)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}

// Optional helper if your older views call it.
// If you already have a different positioning modifier, keep yours and delete this.
extension View {
    func floatingAddButtonPosition(padding: CGFloat = 20) -> some View {
        self.padding(.trailing, padding)
            .padding(.bottom, padding)
    }
}

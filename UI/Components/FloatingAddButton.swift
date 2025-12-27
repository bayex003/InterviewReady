import SwiftUI

struct FloatingAddButton: View {
    let action: () -> Void
    var size: CGFloat = 56

    var body: some View {
        Button(action: action) {
            Image(systemName: "plus")
                .font(.title2.weight(.bold))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(Color.sage500)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.15), radius: 10, y: 6)
        }
        .buttonStyle(.plain)
    }
}

extension View {
    func floatingAddButtonPosition() -> some View {
        self
            .padding(.trailing, 20)
            .padding(.bottom, 24)
    }
}

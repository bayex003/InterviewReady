import SwiftUI

extension View {
    // 1. Helper to hide keyboard programmatically
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// 2. A modifier that detects background taps
struct TapToDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onTapGesture {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            }
    }
}

extension View {
    func tapToDismissKeyboard() -> some View {
        self.modifier(TapToDismissModifier())
    }
}

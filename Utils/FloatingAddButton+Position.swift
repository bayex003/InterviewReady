import SwiftUI

/// Positions the floating "+" button consistently across screens.
private struct FloatingAddButtonPosition: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.trailing, 18)
            .padding(.bottom, 28)
    }
}

// NOTE: Removed duplicate floatingAddButtonPosition() extension.
// Keep a single implementation in ViewExtensions.swift (or re-add here if needed).

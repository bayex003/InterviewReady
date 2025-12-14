import SwiftUI

struct FloatingTabBarHiddenModifier: ViewModifier {
    @EnvironmentObject private var router: AppRouter

    func body(content: Content) -> some View {
        content
            .onAppear { router.isTabBarHidden = true }
            .onDisappear { router.isTabBarHidden = false }
    }
}

extension View {
    func hidesFloatingTabBar() -> some View {
        modifier(FloatingTabBarHiddenModifier())
    }
}

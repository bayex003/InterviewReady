import SwiftUI

private struct FloatingTabBarHiddenPreferenceKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        // If ANY child wants it hidden, hide it.
        value = value || nextValue()
    }
}

extension View {
    /// Call this on screens where the floating tab bar should NOT show (detail/edit/add screens).
    func hidesFloatingTabBar(_ hidden: Bool = true) -> some View {
        preference(key: FloatingTabBarHiddenPreferenceKey.self, value: hidden)
    }
}

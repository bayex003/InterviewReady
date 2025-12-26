import SwiftUI

/// Minimal Pro gating helper.
/// - Reads Pro status live via closure (avoids stale captured Bool).
/// - Presents paywall via a binding you control in the calling view.
struct ProGate {
    let isPro: () -> Bool
    @Binding var isPaywallPresented: Bool

    init(isPro: @escaping () -> Bool, isPaywallPresented: Binding<Bool>) {
        self.isPro = isPro
        self._isPaywallPresented = isPaywallPresented
    }

    func requirePro(_ action: () -> Void) {
        if isPro() {
            action()
        } else {
            isPaywallPresented = true
        }
    }
}


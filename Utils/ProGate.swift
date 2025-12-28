/// Minimal Pro gating helper.
/// - Reads Pro status live via closure (avoids stale captured Bool).
/// - Presents paywall via a closure you control in the calling view.
struct ProGate {
    let isPro: () -> Bool
    let presentPaywall: () -> Void

    init(isPro: @escaping () -> Bool, presentPaywall: @escaping () -> Void) {
        self.isPro = isPro
        self.presentPaywall = presentPaywall
    }

    func requirePro(_ action: () -> Void) {
        if isPro() {
            action()
        } else {
            presentPaywall()
        }
    }
}


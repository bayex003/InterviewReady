import SwiftUI

struct ProGate {
    let isPro: Bool
    @Binding var isPaywallPresented: Bool

    func requirePro(action: () -> Void) {
        if isPro {
            action()
        } else {
            isPaywallPresented = true
        }
    }
}

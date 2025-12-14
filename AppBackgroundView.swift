import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        // Use your existing token so it matches your design system.
        // The key is: IGNORE SAFE AREA so it fills the whole screen.
        Color.cream50
            .ignoresSafeArea()
    }
}

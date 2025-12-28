import SwiftUI

extension Color {
    // Fallbacks if your palette file didn't get included in the target.
    // These are deliberately subtle; you can map them later to your real palette.
    static let ink100 = Color.primary.opacity(0.10)
    static let ink300 = Color.primary.opacity(0.25)
    static let ink700 = Color.primary.opacity(0.75)
}

import SwiftUI

extension Color {
    // MARK: - Primary Accents
    static let sage500 = Color(hex: "3A7D75")
    static let sage100 = Color(hex: "E0F0EE")
    
    // MARK: - Backgrounds & Surfaces
    static let cream50 = Color(hex: "F9FAFB") // Main background
    static let surfaceWhite = Color(hex: "FFFFFF") // Cards
    
    // MARK: - Text & Ink
    static let ink900 = Color(hex: "111827") // Primary text
    static let ink600 = Color(hex: "4B5563") // Secondary text
    static let ink400 = Color(hex: "9CA3AF") // Placeholders/Tertiary
    
    // MARK: - Status Pills (Examples)
    static let statusBlueBg = Color.blue.opacity(0.15)
    static let statusBlueText = Color.blue.opacity(0.8)
    static let statusGreenBg = Color.green.opacity(0.15)
    static let statusGreenText = Color.green.opacity(0.8)
}

// Helper for hex codes
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

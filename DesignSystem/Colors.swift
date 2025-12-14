import SwiftUI

extension Color {
    // 1. sage500 is REMOVED (It is in your Asset Catalog, so we don't define it here)
    
    // 2. sage100 matches your screenshot error (Missing member)
    static var sage100: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark
                ? UIColor(red: 0.09, green: 0.19, blue: 0.18, alpha: 1)
                : UIColor(red: 0.88, green: 0.94, blue: 0.93, alpha: 1)
        })
    }
    
    // 3. ink200 matches your screenshot error (Missing member)
    static var ink200: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .darkGray : .systemGray5
        })
    }
    
    // MARK: - Backgrounds
    static var cream50: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(white: 0.0, alpha: 1.0) : UIColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1)
        })
    }
    
    static var surfaceWhite: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? UIColor(white: 0.11, alpha: 1.0) : UIColor(white: 1.0, alpha: 1.0)
        })
    }
    
    // MARK: - Text
    static var ink900: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .white : UIColor(white: 0.07, alpha: 1.0)
        })
    }
    
    static var ink600: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .lightGray : UIColor(white: 0.29, alpha: 1.0)
        })
    }
    
    // NEW: Medium neutral between ink600 and ink400
    static var ink500: Color {
        Color(UIColor { trait in
            // Slightly lighter than ink600 in light mode; similar legibility in dark mode
            return trait.userInterfaceStyle == .dark
                ? UIColor(white: 0.75, alpha: 1.0)
                : UIColor(white: 0.40, alpha: 1.0)
        })
    }
    
    static var ink400: Color {
        Color(UIColor { trait in
            return trait.userInterfaceStyle == .dark ? .lightGray : UIColor.systemGray
        })
    }
}

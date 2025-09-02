import SwiftUI

// MARK: - Colors
extension Color {
    // Brand colors
    static let beige = Color(hex: "#EAE3D1", fallback: Color(red: 0.92, green: 0.89, blue: 0.82))
    static let yellow = Color(hex: "#FFD84D", fallback: Color(red: 1.0, green: 0.85, blue: 0.3))
    static let titleDark = Color(hex: "#14342F", fallback: Color(red: 0.08, green: 0.20, blue: 0.18))
    static let titleBrown = Color(hex: "#4C2B21", fallback: Color(red: 0.30, green: 0.17, blue: 0.13))
    static let metaGrey = Color(hex: "#5B626B", fallback: Color(red: 0.36, green: 0.38, blue: 0.42))
    static let outlineBlack = Color.black
    static let badgeRed = Color.red
    static let finalSendBlue = Color(red: 0.607, green: 0.784, blue: 0.933)
    
    // Neutral background colors
    static let neutralBackground = Color(hex: "#F8F9FA", fallback: Color(red: 0.973, green: 0.976, blue: 0.980))
    static let neutralBackgroundAlt = Color(hex: "#F1F3F4", fallback: Color(red: 0.945, green: 0.949, blue: 0.953))
    
    // Brand accent colors
    static let brandBlue = Color(hex: "#353E3E", fallback: Color(red: 0.21, green: 0.24, blue: 0.24))
}

// MARK: - Radius
struct Radius {
    static let card: CGFloat = 16
    static let tab: CGFloat = 8
    static let button: CGFloat = 8
}



// MARK: - Spacing
struct Spacing {
    static let screenH: CGFloat = 16
    static let cardGap: CGFloat = 32
    static let cardPadH: CGFloat = 16
    static let cardPadV: CGFloat = 14
    static let titleGap: CGFloat = 6
    static let tabsToCards: CGFloat = 32
}

// MARK: - Typography
struct Typography {
    static func title() -> Font {
        .title2.weight(.bold) // 22pt, bold weight
    }
    
    static func meta() -> Font {
        .footnote // 13pt, medium weight
    }
    
    static func button() -> Font {
        .callout // 16pt, bold weight
    }
}

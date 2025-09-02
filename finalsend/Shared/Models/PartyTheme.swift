import SwiftUI

struct PartyTheme: Identifiable, Codable, Equatable {
    let id: String
    let name: String
    let description: String
    
    // Background colors
    let cardBackground: String // Hex color for card backgrounds
    let primaryAccent: String // Hex color for primary accents
    let secondaryAccent: String // Hex color for secondary accents
    
    // Text colors
    let textPrimary: String // Hex color for primary text
    let textSecondary: String // Hex color for secondary text
    
    static let `default` = PartyTheme(
        id: "default",
        name: "Default",
        description: "Clean white background",
        cardBackground: "#FFFFFF",
        primaryAccent: "#353E3E",
        secondaryAccent: "#353E3E",
        textPrimary: "#000000",
        textSecondary: "#666666"
    )
    
            static let green = PartyTheme(
            id: "green",
            name: "Green",
            description: "Fresh green background",
            cardBackground: "#5CA735",
            primaryAccent: "#353E3E",
            secondaryAccent: "#30D158",
            textPrimary: "#1A1A1A",
            textSecondary: "#4A5568"
        )
        
        static let pink = PartyTheme(
            id: "pink",
            name: "Pink",
            description: "Soft pink background",
            cardBackground: "#F5DADF",
            primaryAccent: "#353E3E",
            secondaryAccent: "#30D158",
            textPrimary: "#1A1A1A",
            textSecondary: "#4A5568"
        )
        
        static let powderBlue = PartyTheme(
            id: "powder_blue",
            name: "Powder Blue",
            description: "Soft powder blue background",
            cardBackground: "#97C0E6",
            primaryAccent: "#353E3E",
            secondaryAccent: "#30D158",
            textPrimary: "#1A1A1A",
            textSecondary: "#4A5568"
        )
        
        static let darkBlue = PartyTheme(
            id: "dark_blue",
            name: "Dark Blue",
            description: "Deep blue background",
            cardBackground: "#00205B",
            primaryAccent: "#353E3E",
            secondaryAccent: "#30D158",
            textPrimary: "#FFFFFF",
            textSecondary: "#E5E5E5"
        )
        
        static let aqua = PartyTheme(
            id: "aqua",
            name: "Aqua",
            description: "Fresh aqua background",
            cardBackground: "#008E98",
            primaryAccent: "#353E3E",
            secondaryAccent: "#30D158",
            textPrimary: "#FFFFFF",
            textSecondary: "#E5E5E5"
        )
        
        static let golden = PartyTheme(
            id: "golden",
            name: "Golden",
            description: "Warm golden background",
            cardBackground: "#D3BC8C",
            primaryAccent: "#353E3E",
            secondaryAccent: "#30D158",
            textPrimary: "#1A1A1A",
            textSecondary: "#4A5568"
        )
    
    static let allThemes: [PartyTheme] = [.default, .green, .pink, .powderBlue, .darkBlue, .aqua, .golden]
    
    // Helper computed properties
    var cardBackgroundColor: Color {
        Color(hex: cardBackground) ?? .white
    }
    
    var primaryAccentColor: Color {
        Color(hex: primaryAccent) ?? .blue
    }
    
    var secondaryAccentColor: Color {
        Color(hex: secondaryAccent) ?? .purple
    }
    
    var textPrimaryColor: Color {
        Color(hex: textPrimary) ?? .black
    }
    
    var textSecondaryColor: Color {
        Color(hex: textSecondary) ?? .gray
    }
}



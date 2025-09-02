//
//  Color+Hex.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import SwiftUI

extension Color {
    init?(hex: String) {
        var hex = hex.replacingOccurrences(of: "#", with: "")
        
        // Support shorthand like #FFF
        if hex.count == 3 {
            let r = hex[hex.startIndex]
            let g = hex[hex.index(hex.startIndex, offsetBy: 1)]
            let b = hex[hex.index(hex.startIndex, offsetBy: 2)]
            hex = "\(r)\(r)\(g)\(g)\(b)\(b)"
        }

        guard hex.count == 6, let rgb = UInt64(hex, radix: 16) else {
            assertionFailure("Invalid hex color string: \(hex)")
            return nil
        }

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0

        self.init(red: r, green: g, blue: b)
    }
    
    // Non-optional version that provides a fallback color
    init(hex: String, fallback: Color = .gray) {
        if let color = Color(hex: hex) {
            self = color
        } else {
            self = fallback
        }
    }
}

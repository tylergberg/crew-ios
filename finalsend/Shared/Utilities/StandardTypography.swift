import SwiftUI

// MARK: - Standard Typography System
// Based on Apple's Human Interface Guidelines
// https://developer.apple.com/design/human-interface-guidelines

struct StandardTypography {
    
    // MARK: - Text Styles (HIG Compliant)
    
    /// Large Title - 34pt, Heavy weight
    static let largeTitle = Font.system(size: 34, weight: .heavy, design: .default)
    
    /// Title 1 - 28pt, Bold weight
    static let title1 = Font.system(size: 28, weight: .bold, design: .default)
    
    /// Title 2 - 22pt, Bold weight
    static let title2 = Font.system(size: 22, weight: .bold, design: .default)
    
    /// Title 3 - 20pt, Semibold weight
    static let title3 = Font.system(size: 20, weight: .semibold, design: .default)
    
    /// Headline - 17pt, Semibold weight
    static let headline = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Body - 17pt, Regular weight
    static let body = Font.system(size: 17, weight: .regular, design: .default)
    
    /// Callout - 16pt, Regular weight
    static let callout = Font.system(size: 16, weight: .regular, design: .default)
    
    /// Subheadline - 15pt, Regular weight
    static let subheadline = Font.system(size: 15, weight: .regular, design: .default)
    
    /// Footnote - 13pt, Regular weight
    static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    
    /// Caption 1 - 12pt, Regular weight
    static let caption1 = Font.system(size: 12, weight: .regular, design: .default)
    
    /// Caption 2 - 11pt, Regular weight
    static let caption2 = Font.system(size: 11, weight: .regular, design: .default)
    
    // MARK: - Button Typography
    
    /// Primary Button - 17pt, Semibold weight
    static let buttonPrimary = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Secondary Button - 15pt, Medium weight
    static let buttonSecondary = Font.system(size: 15, weight: .medium, design: .default)
    
    /// Small Button - 13pt, Medium weight
    static let buttonSmall = Font.system(size: 13, weight: .medium, design: .default)
    
    // MARK: - Navigation Typography
    
    /// Navigation Title - 17pt, Semibold weight
    static let navigationTitle = Font.system(size: 17, weight: .semibold, design: .default)
    
    /// Navigation Bar Button - 17pt, Regular weight
    static let navigationBarButton = Font.system(size: 17, weight: .regular, design: .default)
    
    // MARK: - Tab Bar Typography
    
    /// Tab Bar Item - 10pt, Regular weight
    static let tabBarItem = Font.system(size: 10, weight: .regular, design: .default)
    
    // MARK: - Icon Sizes (HIG Compliant)
    
    /// Large Icon - 48pt
    static let iconLarge: CGFloat = 48
    
    /// Medium Icon - 32pt
    static let iconMedium: CGFloat = 32
    
    /// Small Icon - 24pt
    static let iconSmall: CGFloat = 24
    
    /// Extra Small Icon - 16pt
    static let iconExtraSmall: CGFloat = 16
    
    // MARK: - Line Heights (HIG Compliant)
    
    /// Standard line height multiplier
    static let lineHeightStandard: CGFloat = 1.2
    
    /// Tight line height multiplier
    static let lineHeightTight: CGFloat = 1.1
    
    /// Loose line height multiplier
    static let lineHeightLoose: CGFloat = 1.4
    
    // MARK: - Letter Spacing
    
    /// Standard letter spacing
    static let letterSpacingStandard: CGFloat = 0.0
    
    /// Tight letter spacing for headlines
    static let letterSpacingTight: CGFloat = -0.5
    
    /// Loose letter spacing for emphasis
    static let letterSpacingLoose: CGFloat = 0.5
}

// MARK: - Typography Extensions

extension Text {
    /// Apply large title styling
    func largeTitle() -> some View {
        self.font(StandardTypography.largeTitle)
    }
    
    /// Apply title 1 styling
    func title1() -> some View {
        self.font(StandardTypography.title1)
    }
    
    /// Apply title 2 styling
    func title2() -> some View {
        self.font(StandardTypography.title2)
    }
    
    /// Apply title 3 styling
    func title3() -> some View {
        self.font(StandardTypography.title3)
    }
    
    /// Apply headline styling
    func headline() -> some View {
        self.font(StandardTypography.headline)
    }
    
    /// Apply body styling
    func body() -> some View {
        self.font(StandardTypography.body)
    }
    
    /// Apply callout styling
    func callout() -> some View {
        self.font(StandardTypography.callout)
    }
    
    /// Apply subheadline styling
    func subheadline() -> some View {
        self.font(StandardTypography.subheadline)
    }
    
    /// Apply footnote styling
    func footnote() -> some View {
        self.font(StandardTypography.footnote)
    }
    
    /// Apply caption 1 styling
    func caption1() -> some View {
        self.font(StandardTypography.caption1)
    }
    
    /// Apply caption 2 styling
    func caption2() -> some View {
        self.font(StandardTypography.caption2)
    }
    
    /// Apply primary button styling
    func buttonPrimary() -> some View {
        self.font(StandardTypography.buttonPrimary)
    }
    
    /// Apply secondary button styling
    func buttonSecondary() -> some View {
        self.font(StandardTypography.buttonSecondary)
    }
    
    /// Apply small button styling
    func buttonSmall() -> some View {
        self.font(StandardTypography.buttonSmall)
    }
}

// MARK: - Button Extensions

extension Button where Label == Text {
    /// Apply primary button styling
    func buttonPrimary() -> some View {
        self.font(StandardTypography.buttonPrimary)
    }
    
    /// Apply secondary button styling
    func buttonSecondary() -> some View {
        self.font(StandardTypography.buttonSecondary)
    }
    
    /// Apply small button styling
    func buttonSmall() -> some View {
        self.font(StandardTypography.buttonSmall)
    }
}

// MARK: - Icon Extensions

extension Image {
    /// Apply large icon sizing
    func iconLarge() -> some View {
        self.font(.system(size: StandardTypography.iconLarge))
    }
    
    /// Apply medium icon sizing
    func iconMedium() -> some View {
        self.font(.system(size: StandardTypography.iconMedium))
    }
    
    /// Apply small icon sizing
    func iconSmall() -> some View {
        self.font(.system(size: StandardTypography.iconSmall))
    }
    
    /// Apply extra small icon sizing
    func iconExtraSmall() -> some View {
        self.font(.system(size: StandardTypography.iconExtraSmall))
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Large Title").largeTitle()
        Text("Title 1").title1()
        Text("Title 2").title2()
        Text("Title 3").title3()
        Text("Headline").headline()
        Text("Body Text").body()
        Text("Callout").callout()
        Text("Subheadline").subheadline()
        Text("Footnote").footnote()
        Text("Caption 1").caption1()
        Text("Caption 2").caption2()
        
        Button("Primary Button") {}.buttonPrimary()
        Button("Secondary Button") {}.buttonSecondary()
        Button("Small Button") {}.buttonSmall()
        
        HStack {
            Image(systemName: "star").iconLarge()
            Image(systemName: "star").iconMedium()
            Image(systemName: "star").iconSmall()
            Image(systemName: "star").iconExtraSmall()
        }
    }
    .padding()
}

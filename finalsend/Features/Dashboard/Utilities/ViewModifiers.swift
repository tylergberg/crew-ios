import SwiftUI

// MARK: - Card Container Modifier
struct CardContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .cornerRadius(Radius.card)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .stroke(Color.outlineBlack, lineWidth: 1.5)
            )
            .shadow(
                color: .black.opacity(0.15),
                radius: 6,
                x: 0,
                y: 2
            )
    }
}

// MARK: - Polaroid Card Container Modifier
struct PolaroidCardContainer: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16) // Horizontal padding for sides
            .padding(.top, 16) // Top padding
            .padding(.bottom, 20) // Reduced bottom padding for label zone
            .background(Color.white) // White background for the frame
            .cornerRadius(Radius.button) // Same rounded corners as buttons
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(Color.outlineBlack, lineWidth: 1.5)
            )
            .shadow(
                color: .black.opacity(0.12),
                radius: 8,
                x: 1,
                y: 3
            )
    }
}

// MARK: - Title Text Modifier
struct TitleText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 18, weight: .bold)) // Smaller font for Polaroid titles
            .foregroundColor(Color.titleDark)
            .lineLimit(1) // Single line only
            .truncationMode(.tail) // Add "..." if too long
    }
}

// MARK: - Meta Text Modifier
struct MetaText: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(Typography.meta())
            .foregroundColor(Color.metaGrey)
    }
}

// MARK: - Button Style Modifier
struct NewButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .foregroundColor(.black)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(hex: "#9BC8EE"))
            .cornerRadius(Radius.button)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.button)
                    .stroke(Color.outlineBlack, lineWidth: 1.5)
            )
            .shadow(
                color: .black.opacity(0.12),
                radius: 3,
                x: 0,
                y: 1
            )
    }
}

// MARK: - View Extensions
extension View {
    func cardContainer() -> some View {
        modifier(CardContainer())
    }
    
    func polaroidCardContainer() -> some View {
        modifier(PolaroidCardContainer())
    }
    
    func titleText() -> some View {
        modifier(TitleText())
    }
    
    func metaText() -> some View {
        modifier(MetaText())
    }
    
    func newButtonStyle() -> some View {
        modifier(NewButtonStyle())
    }
}

import SwiftUI

struct ImmersivePartyHeader: View {
    let coverURL: URL?
    let partyName: String
    let isAdminOrOrganizer: Bool
    let onBackTapped: () -> Void
    let onChatTapped: () -> Void
    let onSettingsTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Background Image (Full Height)
            Group {
                if let url = coverURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            Color(hex: "#FDF3E7") ?? Color.gray.opacity(0.3)
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width, height: 280)
                                .clipped()
                        case .failure:
                            Color(hex: "#FDF3E7") ?? Color.gray.opacity(0.3)
                        @unknown default:
                            Color(hex: "#FDF3E7") ?? Color.gray.opacity(0.3)
                        }
                    }
                } else {
                    Color(hex: "#FDF3E7") ?? Color.gray.opacity(0.3)
                }
            }
            .frame(width: UIScreen.main.bounds.width, height: 280)
            .zIndex(0)
            
            // Gradient Overlay for Readability
            VStack {
                Spacer()
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.2),
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 140)
            }
            .frame(height: 280)
            .zIndex(1)
            
            // Party Title (Centered on Photo)
            VStack {
                Spacer()
                Text(partyName)
                    .font(.system(size: 32, weight: .heavy, design: .serif))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.8), radius: 4, x: 2, y: 2)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 60) // More space from tab bar
            }
            .frame(height: 280)
            .zIndex(2)
            
            // Top Action Buttons (Translucent)
            VStack {
                HStack {
                    Button(action: onBackTapped) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(12)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Back")
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        Button(action: onChatTapped) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .accessibilityLabel("Open group chat")
                        
                        if isAdminOrOrganizer {
                            Button(action: onSettingsTapped) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                            .contentShape(Rectangle())
                            .accessibilityLabel("Settings")
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, getSafeAreaTop() + 8)
                
                Spacer()
            }
            .frame(height: 280)
            .zIndex(3)
        }
        .frame(width: UIScreen.main.bounds.width, height: 280)
        .clipped()
    }
    
    private func getSafeAreaTop() -> CGFloat {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            return window.safeAreaInsets.top
        }
        return 47
    }
}

#Preview {
    ImmersivePartyHeader(
        coverURL: URL(string: "https://example.com/cover.jpg"),
        partyName: "Teicher Takes Texas",
        isAdminOrOrganizer: true,
        onBackTapped: {},
        onChatTapped: {},
        onSettingsTapped: {}
    )
    .background(Color(hex: "#9BC8EE"))
}

import SwiftUI

struct ExtendedPartyHeader: View {
    let coverURL: URL?
    let partyName: String
    let isAdminOrOrganizer: Bool
    @Binding var selectedTab: PartyDetailTab
    let visibleTabs: [PartyDetailTab]
    let onBackTapped: () -> Void
    let onChatTapped: () -> Void
    let onSettingsTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Extended Background Image with Gradient Overlay
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
                                .frame(width: UIScreen.main.bounds.width, height: 320) // Reduced height
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
            .frame(width: UIScreen.main.bounds.width, height: 320) // Extended height
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.3),
                        Color.black.opacity(0.6),
                        Color.black.opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 320)
                .allowsHitTesting(false)
            )
            .zIndex(0)
            
            // Content Overlay
            VStack(spacing: 0) {
                // Top Action Buttons
                HStack {
                    Button(action: onBackTapped) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.titleDark)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.button))
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
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Back")
                    
                    Spacer()
                    
                    // Chat Button (always visible)
                    Button(action: onChatTapped) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Color.titleDark)
                            .frame(width: 36, height: 36)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: Radius.button))
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
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                    .accessibilityLabel("Open group chat")
                }
                .padding(.horizontal, 24)
                .padding(.top, getSafeAreaTop() + 8)
                
                Spacer()
                
                // Party Title (Bottom-Center, above tabs)
                Text(partyName)
                    .font(.title.weight(.black))
                    .foregroundColor(Color.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.6), radius: 3, x: 1, y: 1)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 0)
                
                // Tab Navigation (at the very bottom)
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(visibleTabs.enumerated()), id: \.element) { index, tab in
                                tabButton(for: tab)
                                    .padding(.leading, index == 0 ? 24 : 0)
                                    .padding(.trailing, index == visibleTabs.count - 1 ? 24 : 0)
                            }
                        }
                        .padding(.vertical, 6)
                    }
                    .onAppear {
                        // Scroll to the selected tab when the view appears
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(selectedTab.rawValue, anchor: .center)
                        }
                    }
                    .onChange(of: selectedTab) { newValue in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo(newValue.rawValue, anchor: .center)
                        }
                    }
                }
                .frame(height: 64)
                .padding(.bottom, 4)
            }
            .zIndex(2)
        }
                    .frame(width: UIScreen.main.bounds.width, height: 320)
            .clipped()
    }
    
    private func tabButton(for tab: PartyDetailTab) -> some View {
        Button(action: {
            selectedTab = tab
        }) {
            Text(tab.displayName.uppercased())
                .font(.footnote.weight(.bold))
                .foregroundColor(Color.titleDark)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(selectedTab == tab ? Color.yellow : Color.white)
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
        .id(tab.rawValue)
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
    ExtendedPartyHeader(
        coverURL: URL(string: "https://example.com/cover.jpg"),
        partyName: "Teicher Takes Texas",
        isAdminOrOrganizer: true,
        selectedTab: .constant(.overview),
        visibleTabs: [.overview, .crew, .itinerary],
        onBackTapped: {},
        onChatTapped: {},
        onSettingsTapped: {}
    )
    .background(Color(hex: "#9BC8EE"))
}

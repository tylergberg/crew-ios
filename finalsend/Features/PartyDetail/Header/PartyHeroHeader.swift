//
//  PartyHeroHeader.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-15.
//

import SwiftUI

struct PartyHeroHeader: View {
    let coverURL: URL?
    let partyName: String
    let isAdminOrOrganizer: Bool
    let onBackTapped: () -> Void
    let onChatTapped: () -> Void
    let onSettingsTapped: () -> Void
    
    var body: some View {
        ZStack {
            // Background Image with Gradient Overlay
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
                                .frame(width: UIScreen.main.bounds.width, height: 300)
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
            .frame(width: UIScreen.main.bounds.width, height: 300)
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.4),
                        Color.black.opacity(0.6)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 300)
                .allowsHitTesting(false)
            )
            .zIndex(0)
            
            // Party Title (Bottom-Center)
            VStack {
                Spacer()
                Text(partyName)
                    .font(.title.weight(.black))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .shadow(color: Color.black.opacity(0.6), radius: 3, x: 1, y: 1)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 14)
            }
            .zIndex(2)
            
            // Top Action Buttons
            VStack {
                HStack {
                    Button(action: onBackTapped) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.titleDark)
                            .padding(10)
                            .background(Color.yellow)
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
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(Color.titleDark)
                            .padding(10)
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
            }
            .zIndex(3)
        }
        .frame(width: UIScreen.main.bounds.width, height: 300)
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
    PartyHeroHeader(
        coverURL: URL(string: "https://example.com/cover.jpg"),
        partyName: "Teicher Takes Texas",
        isAdminOrOrganizer: true,
        onBackTapped: {},
        onChatTapped: {},
        onSettingsTapped: {}
    )
    .background(Color(hex: "#9BC8EE"))
}

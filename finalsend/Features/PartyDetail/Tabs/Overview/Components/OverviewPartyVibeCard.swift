//
//  OverviewPartyVibeCard.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct OverviewPartyVibeCard: View {
    let vibeTags: [String]
    var onEdit: () -> Void

    var body: some View {
        OverviewCard(
            iconName: "sparkles",
            title: "Party Vibe",
            editable: true,
            onEdit: onEdit
        ) {
            VStack(alignment: .leading, spacing: 8) {
                if vibeTags.isEmpty {
                    Text("No vibe tags set yet")
                        .font(.subheadline)
                        .foregroundColor(Color(red: 0.25, green: 0.11, blue: 0.09))
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 8)], alignment: .leading, spacing: 8) {
                        ForEach(vibeTags, id: \.self) { tag in
                            Text(tag)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(getVibeTagColor(tag))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.black, lineWidth: 2)
                                )
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 2, y: 2)
                        }
                    }
                }
            }
        }
    }
    
    private func getVibeTagColor(_ tag: String) -> Color {
        let personalityTags = ["Chill", "Rowdy", "Fancy", "Outdoorsy", "Foodie", "Nerdy", "Athletic", "Bougie", "Wild"]
        return personalityTags.contains(tag) ? Color(red: 0.29, green: 0.51, blue: 0.91) : Color(red: 0.93, green: 0.41, blue: 0.25)
    }
}

#Preview {
    OverviewPartyVibeCard(
        vibeTags: ["Chill", "Great Food", "Live Music"],
        onEdit: {}
    )
}

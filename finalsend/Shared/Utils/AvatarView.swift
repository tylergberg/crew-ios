//
//  AvatarView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-06.
//

import SwiftUI

struct AvatarView: View {
    let attendee: PartyAttendee
    
    var body: some View {
        Group {
            if let avatarUrl = attendee.avatarUrl, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.black, lineWidth: 2)
        )
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(CrewUtilities.getAvatarColor(for: attendee.fullName))
            
            Text(attendee.initials)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    AvatarView(
        attendee: PartyAttendee(
            id: UUID(),
            userId: "1",
            partyId: "1",
            fullName: "John Doe",
            email: "john@example.com",
            avatarUrl: nil,
            role: .guest,
            rsvpStatus: .confirmed,
            specialRole: nil,
            invitedAt: Date(),
            respondedAt: Date(),
            isCurrentUser: false
        )
    )
}


//
//  AvatarView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-06.
//

import SwiftUI
import Foundation

struct AvatarView: View {
    let attendee: PartyAttendee
    @State private var versionTick: Int = 0
    @State private var imageLoadedSuccessfully: Bool = false
    
    var body: some View {
        Group {
            if let avatarUrl = attendee.avatarUrl, !avatarUrl.isEmpty {
                let versioned = AvatarURLVersioner.shared.versionedURLString(baseURL: avatarUrl, userId: attendee.userId)
                let finalUrl = versioned ?? avatarUrl
                // Add versionTick to force refresh when avatar is updated
                let refreshUrl = finalUrl + (finalUrl.contains("?") ? "&" : "?") + "refresh=\(versionTick)"
                
                AsyncImage(url: URL(string: refreshUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .onAppear {
                            imageLoadedSuccessfully = true
                        }
                } placeholder: {
                    placeholderView
                        .onAppear {
                            imageLoadedSuccessfully = false
                        }
                }
            } else {
                placeholderView
            }
        }
        .frame(width: 80, height: 80)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.outlineBlack, lineWidth: 2)
        )
        .shadow(
            color: .black.opacity(0.1),
            radius: 8,
            x: 0,
            y: 2
        )
        .onReceive(NotificationCenter.default.publisher(for: .avatarUpdated)) { notif in
            if let changedId = notif.userInfo?["userId"] as? String, changedId == attendee.userId {
                versionTick &+= 1
            }
        }
    }
    
    private var placeholderView: some View {
        ZStack {
            Circle()
                .fill(imageLoadedSuccessfully ? CrewUtilities.getAvatarColor(for: attendee.fullName) : Color(hex: "#353E3E"))
            
            Text(attendee.initials)
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Compact Avatar View for List Rows
struct CompactAvatarView: View {
    let attendee: PartyAttendee
    @State private var versionTick: Int = 0
    @State private var imageLoadedSuccessfully: Bool = false
    
    var body: some View {
        Group {
            if let avatarUrl = attendee.avatarUrl, !avatarUrl.isEmpty {
                let versioned = AvatarURLVersioner.shared.versionedURLString(baseURL: avatarUrl, userId: attendee.userId)
                let finalUrl = versioned ?? avatarUrl
                // Add versionTick to force refresh when avatar is updated
                let refreshUrl = finalUrl + (finalUrl.contains("?") ? "&" : "?") + "refresh=\(versionTick)"
                
                AsyncImage(url: URL(string: refreshUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .onAppear {
                            imageLoadedSuccessfully = true
                        }
                } placeholder: {
                    compactPlaceholderView
                        .onAppear {
                            imageLoadedSuccessfully = false
                        }
                }
            } else {
                compactPlaceholderView
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(Circle())
        .overlay(
            Circle()
                .strokeBorder(Color.outlineBlack, lineWidth: 1.5)
        )
        .shadow(
            color: .black.opacity(0.08),
            radius: 4,
            x: 0,
            y: 1
        )
        .onReceive(NotificationCenter.default.publisher(for: .avatarUpdated)) { notif in
            if let changedId = notif.userInfo?["userId"] as? String, changedId == attendee.userId {
                versionTick &+= 1
            }
        }
    }
    
    private var compactPlaceholderView: some View {
        ZStack {
            Circle()
                .fill(imageLoadedSuccessfully ? CrewUtilities.getAvatarColor(for: attendee.fullName) : Color(hex: "#353E3E"))
            
            Text(attendee.initials)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AvatarView(attendee: PartyAttendee(fullName: "John Doe"))
        
        CompactAvatarView(attendee: PartyAttendee(fullName: "Jane Smith"))
    }
}


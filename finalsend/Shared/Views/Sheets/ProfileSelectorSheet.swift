//
//  ProfileSelectorSheet.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI

struct ProfileSelectorSheet: View {
    let attendees: [PartyAttendee]
    let selectedAttendeeId: UUID?
    let onAttendeeSelected: (PartyAttendee) -> Void
    let onDismiss: () -> Void
    
    @State private var searchText = ""
    @State private var selectedAttendee: PartyAttendee?
    
    var filteredAttendees: [PartyAttendee] {
        if searchText.isEmpty {
            return attendees
        } else {
            return attendees.filter { attendee in
                attendee.fullName.localizedCaseInsensitiveContains(searchText) ||
                (attendee.email ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText, placeholder: "Search attendees...")
                    .padding(.horizontal, LodgingTheme.padding)
                    .padding(.top, LodgingTheme.padding)
                
                // Attendees list
                ScrollView {
                    LazyVStack(spacing: LodgingTheme.tightSpacing) {
                        ForEach(filteredAttendees) { attendee in
                            AttendeeRow(
                                attendee: attendee,
                                isSelected: selectedAttendeeId == attendee.id,
                                onTap: {
                                    selectedAttendee = attendee
                                }
                            )
                        }
                    }
                    .padding(.horizontal, LodgingTheme.padding)
                    .padding(.top, LodgingTheme.spacing)
                }
                
                // Bottom button
                VStack(spacing: LodgingTheme.spacing) {
                    if let selectedAttendee = selectedAttendee {
                        Button(action: {
                            onAttendeeSelected(selectedAttendee)
                            onDismiss()
                        }) {
                            Text("Assign \(selectedAttendee.fullName)")
                                .font(LodgingTheme.bodyFont)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, LodgingTheme.padding)
                                .background(LodgingTheme.primaryYellow)
                                .cornerRadius(LodgingTheme.smallCornerRadius)
                        }
                        .padding(.horizontal, LodgingTheme.padding)
                    }
                    
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(LodgingTheme.bodyFont)
                            .foregroundColor(LodgingTheme.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, LodgingTheme.padding)
                            .background(Color.clear)
                            .cornerRadius(LodgingTheme.smallCornerRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LodgingTheme.smallCornerRadius)
                                    .stroke(LodgingTheme.borderColor, lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, LodgingTheme.padding)
                }
                .padding(.bottom, LodgingTheme.padding)
            }
            .background(LodgingTheme.backgroundYellow)
            .navigationTitle("Select Attendee")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(LodgingTheme.primaryYellow)
                }
            }
        }
    }
}

struct AttendeeRow: View {
    let attendee: PartyAttendee
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Background layer
                RoundedRectangle(cornerRadius: LodgingTheme.smallCornerRadius)
                    .fill(Color.white)
                
                // Shadow effect
                RoundedRectangle(cornerRadius: LodgingTheme.smallCornerRadius)
                    .fill(Color.clear)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                
                // Content layer
                HStack(spacing: LodgingTheme.spacing) {
                    // Avatar
                    AvatarView(attendee: attendee)
                        .frame(width: 40, height: 40)
                        .allowsHitTesting(false) // Prevent avatar from interfering with button tap
                    
                    // Attendee info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(attendee.fullName)
                            .font(LodgingTheme.bodyFont)
                            .fontWeight(.medium)
                            .foregroundColor(LodgingTheme.textPrimary)
                        
                        Text(attendee.email ?? "")
                            .font(LodgingTheme.smallFont)
                            .foregroundColor(LodgingTheme.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(LodgingTheme.primaryYellow)
                            .font(.system(size: 20))
                            .allowsHitTesting(false) // Prevent selection indicator from interfering with button tap
                    } else {
                        Image(systemName: "circle")
                            .foregroundColor(LodgingTheme.borderColor)
                            .font(.system(size: 20))
                            .allowsHitTesting(false) // Prevent selection indicator from interfering with button tap
                    }
                }
                .padding(LodgingTheme.padding)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contentShape(Rectangle()) // Ensure the entire button area is tappable
        .padding(.bottom, 8) // Add spacing between rows instead of divider
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(LodgingTheme.textSecondary)
            
            TextField(placeholder, text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(LodgingTheme.bodyFont)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(LodgingTheme.textSecondary)
                }
            }
        }
        .padding(LodgingTheme.smallPadding)
        .background(Color.white)
        .cornerRadius(LodgingTheme.smallCornerRadius)
        .applySubtleShadow()
    }
}

#Preview {
    ProfileSelectorSheet(
        attendees: [
            PartyAttendee(
                id: UUID(),
                userId: "1",
                partyId: "1",
                fullName: "John Doe",
                email: "john@example.com",
                avatarUrl: nil,
                role: .attendee,
                rsvpStatus: .confirmed,
                specialRole: nil,
                invitedAt: Date(),
                respondedAt: Date(),
                isCurrentUser: false
            ),
            PartyAttendee(
                id: UUID(),
                userId: "2",
                partyId: "1",
                fullName: "Jane Smith",
                email: "jane@example.com",
                avatarUrl: nil,
                role: .attendee,
                rsvpStatus: .confirmed,
                specialRole: nil,
                invitedAt: Date(),
                respondedAt: Date(),
                isCurrentUser: false
            )
        ],
        selectedAttendeeId: nil,
        onAttendeeSelected: { _ in },
        onDismiss: {}
    )
}


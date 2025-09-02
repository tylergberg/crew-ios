//
//  CrewTabView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-06.
//

import SwiftUI

struct CrewTabView: View {
    let partyId: UUID
    let currentUserId: UUID
    let crewService: CrewService

    @EnvironmentObject var dataManager: PartyDataManager
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAttendee: PartyAttendee?

    var body: some View {
        NavigationView {
            List {
                if dataManager.isAttendeesLoading {
                    Section {
                        HStack {
                            ProgressView()
                            Text("Loading attendees…").foregroundColor(.secondary)
                        }
                    }
                } else if dataManager.attendees.isEmpty {
                    Section {
                        Text("No attendees yet").foregroundColor(.secondary)
                    }
                } else {
                    Section(header: Text("Crew (\(dataManager.attendees.count))")) {
                        ForEach(dataManager.attendees) { attendee in
                            Button(action: {
                                print("👤 CrewTabView: Row tapped for \(attendee.fullName) - id: \(attendee.userId)")
                                selectedAttendee = attendee
                            }) {
                                HStack(spacing: 12) {
                                    CompactAvatarView(attendee: attendee)
                                        .frame(width: 36, height: 36)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(attendee.fullName).font(.body).fontWeight(.semibold)
                                        Text(attendee.role.displayName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").foregroundColor(.secondary)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Crew")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(item: $selectedAttendee) { attendee in
            UnifiedProfileView(
                userId: attendee.userId,
                partyContext: PartyContext(
                    role: attendee.role,
                    rsvpStatus: attendee.rsvpStatus,
                    attendeeName: attendee.fullName,
                    attendeeId: attendee.id,
                    canChangeRole: true,
                    canManageAttendee: true,
                    partyId: partyId.uuidString,
                    specialRole: attendee.specialRole
                ),
                isOwnProfile: attendee.userId.lowercased() == currentUserId.uuidString.lowercased(),
                crewService: crewService,
                onCrewDataUpdated: { Task { await dataManager.loadAttendees(partyId: partyId.uuidString, currentUserId: currentUserId.uuidString) } },
                showTaskManagement: attendee.userId.lowercased() == currentUserId.uuidString.lowercased()
            )
        }
    }
}


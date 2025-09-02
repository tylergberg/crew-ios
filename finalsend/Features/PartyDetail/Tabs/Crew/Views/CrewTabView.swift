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
                    // Build grouped lists
                    let specialRole = dataManager.attendees
                        .filter { ($0.specialRole?.isEmpty == false) }
                        .sorted { $0.fullName < $1.fullName }
                    let confirmed = dataManager.attendees
                        .filter { $0.rsvpStatus == .confirmed && ($0.specialRole?.isEmpty ?? true) }
                        .sorted { $0.fullName < $1.fullName }
                    let pending = dataManager.attendees
                        .filter { $0.rsvpStatus == .pending && ($0.specialRole?.isEmpty ?? true) }
                        .sorted { $0.fullName < $1.fullName }
                    let declined = dataManager.attendees
                        .filter { $0.rsvpStatus == .declined && ($0.specialRole?.isEmpty ?? true) }
                        .sorted { $0.fullName < $1.fullName }

                    if !specialRole.isEmpty {
                        Section(header: Text("Special Role")) {
                            ForEach(specialRole) { attendee in
                                attendeeRow(attendee)
                            }
                        }
                    }

                    if !confirmed.isEmpty {
                        Section(header: Text("The Crew")) {
                            ForEach(confirmed) { attendee in
                                attendeeRow(attendee)
                            }
                        }
                    }

                    if !pending.isEmpty {
                        Section(header: Text("Pending")) {
                            ForEach(pending) { attendee in
                                attendeeRow(attendee)
                            }
                        }
                    }

                    if !declined.isEmpty {
                        Section(header: Text("Declined")) {
                            ForEach(declined) { attendee in
                                attendeeRow(attendee)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Crew")
            .navigationBarTitleDisplayMode(.inline)
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
private extension CrewTabView {
    func attendeeRow(_ attendee: PartyAttendee) -> some View {
        Button(action: {
            print("👤 CrewTabView: Row tapped for \(attendee.fullName) - id: \(attendee.userId)")
            selectedAttendee = attendee
        }) {
            HStack(spacing: 12) {
                CompactAvatarView(attendee: attendee)
                    .frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(attendee.fullName)
                        .font(.body)
                        .fontWeight(.semibold)
                    HStack(spacing: 6) {
                        Text(attendee.role.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if let special = attendee.specialRole, !special.isEmpty {
                            Text("• \(special.capitalized)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Text("• \(attendee.rsvpStatus.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
                if attendee.isCurrentUser {
                    Text("You")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Image(systemName: "chevron.right").foregroundColor(.secondary)
            }
        }
        .buttonStyle(.plain)
    }
}


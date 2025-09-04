//
//  CrewService.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-06.
//
import Foundation
import Supabase

final class CrewService {
    struct InviteTokenRow: Decodable {
        let token: UUID
    }
    struct InviteInsertPayload: Encodable {
        let party_id: UUID
        let role: String
        let special_role: String?
    }

    func fetchAttendees(for partyId: UUID) async throws -> [PartyAttendee] {
        []
    }

    @MainActor
    func removeAttendee(_ attendeeId: UUID, from partyId: UUID) async throws {}
    func removeAttendee(_ attendeeId: UUID) async -> Bool { true }

    @MainActor
    func setSpecialRole(_ role: String?, for attendeeId: UUID, partyId: UUID) async throws {}
    func setSpecialRole(for attendeeId: UUID, specialRole: String?) async -> Bool { true }

    @MainActor
    func updateRsvpStatus(for attendeeId: UUID, to status: RsvpStatus) async -> Bool {
        do {
            let client = SupabaseManager.shared.client
            let statusString: String
            switch status {
            case .confirmed:
                statusString = "confirmed"
            case .pending, .guest:
                statusString = "pending"
            case .declined:
                statusString = "declined"
            }

            _ = try await client
                .from("party_members")
                .update(["status": statusString])
                .eq("id", value: attendeeId)
                .execute()

            return true
        } catch {
            print("❌ CrewService.updateRsvpStatus error: \(error)")
            return false
        }
    }

    @MainActor
    var errorMessage: String? { nil }

    // MARK: - Invites
    /// Creates a party invite and returns a shareable URL.
    /// Defaults to role "attendee" and no special role.
    func generateInviteLink(partyId: UUID, role: String = "attendee", specialRole: String? = nil) async throws -> String {
        let client = SupabaseManager.shared.client

        // Prepare typed Encodable payload
        let payload = InviteInsertPayload(party_id: partyId, role: role, special_role: (specialRole?.isEmpty == false ? specialRole : nil))

        // Insert and select token
        let response: InviteTokenRow = try await client
            .from("party_invites")
            .insert(payload)
            .select("token")
            .single()
            .execute()
            .value

        // Build canonical website URL for best social previews
        return "https://www.finalsend.co/invite?token=\(response.token.uuidString)"
    }
}


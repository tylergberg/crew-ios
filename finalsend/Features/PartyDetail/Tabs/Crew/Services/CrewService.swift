//
//  CrewService.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-06.
//
import Foundation
import Supabase

final class CrewService {
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
}


//
//  CrewService.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-06.
//
import Foundation

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
    var errorMessage: String? { nil }
}


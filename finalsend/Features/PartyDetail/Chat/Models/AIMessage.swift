//
//  AIMessage.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation

struct AIMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let partyId: UUID
    let senderRole: SenderRole
    let content: String
    let createdAt: Date
    
    enum SenderRole: String, Codable, CaseIterable {
        case user = "user"
        case assistant = "assistant"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case senderRole = "sender_role"
        case content
        case createdAt = "created_at"
    }
    
    init(id: UUID, partyId: UUID, senderRole: SenderRole, content: String, createdAt: Date) {
        self.id = id
        self.partyId = partyId
        self.senderRole = senderRole
        self.content = content
        self.createdAt = createdAt
    }
}


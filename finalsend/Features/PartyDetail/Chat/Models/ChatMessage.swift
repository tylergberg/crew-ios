//
//  ChatMessage.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let message: String
    let createdAt: Date
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case message
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID, partyId: UUID, userId: UUID, message: String, createdAt: Date, updatedAt: Date? = nil) {
        self.id = id
        self.partyId = partyId
        self.userId = userId
        self.message = message
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // Helper method to create ChatMessage from a record dictionary
    static func from(_ record: [String: Any]) throws -> ChatMessage {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let partyIdString = record["party_id"] as? String,
              let partyId = UUID(uuidString: partyIdString),
              let userIdString = record["user_id"] as? String,
              let userId = UUID(uuidString: userIdString),
              let message = record["message"] as? String,
              let createdAtString = record["created_at"] as? String else {
            throw ChatMessageError.invalidRecord
        }
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = dateFormatter.date(from: createdAtString) ?? Date()
        
        var updatedAt: Date? = nil
        if let updatedAtString = record["updated_at"] as? String {
            updatedAt = dateFormatter.date(from: updatedAtString)
        }
        
        return ChatMessage(
            id: id,
            partyId: partyId,
            userId: userId,
            message: message,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

enum ChatMessageError: Error {
    case invalidRecord
}


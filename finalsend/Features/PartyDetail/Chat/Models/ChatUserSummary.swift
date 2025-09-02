//
//  ChatUserSummary.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation

struct ChatUserSummary: Codable, Identifiable, Equatable {
    let userId: UUID
    let name: String
    let avatarURL: URL?
    
    var id: UUID { userId }
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case avatarURL = "avatar_url"
    }
    
    init(userId: UUID, name: String, avatarURL: URL? = nil) {
        self.userId = userId
        self.name = name
        self.avatarURL = avatarURL
    }
}


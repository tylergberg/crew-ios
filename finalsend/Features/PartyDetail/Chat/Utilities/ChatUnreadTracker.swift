//
//  ChatUnreadTracker.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation

class ChatUnreadTracker {
    private let partyId: UUID
    private let userDefaults = UserDefaults.standard
    
    init(partyId: UUID) {
        self.partyId = partyId
    }
    
    var lastOpened: Date? {
        get {
            let key = "chat_last_opened_\(partyId.uuidString)"
            return userDefaults.object(forKey: key) as? Date
        }
        set {
            let key = "chat_last_opened_\(partyId.uuidString)"
            userDefaults.set(newValue, forKey: key)
        }
    }
    
    func unreadCount(for messages: [ChatMessage]) -> Int {
        guard let lastOpened = lastOpened else {
            return messages.count
        }
        
        return messages.filter { $0.createdAt > lastOpened }.count
    }
    
    func markAsRead() {
        lastOpened = Date()
    }
}


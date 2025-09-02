//
//  AIChatStore.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation
import SwiftUI

@MainActor
class AIChatStore: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var isThinking: Bool = false
    
    private let partyId: UUID
    private let service: AIChatService
    
    init(partyId: UUID, service: AIChatService) {
        self.partyId = partyId
        self.service = service
    }
    
    func load() async {
        isLoading = true
        
        do {
            messages = try await service.fetchAll()
        } catch {
            print("Error loading AI messages: \(error)")
        }
        
        isLoading = false
    }
    
    func send(prompt: String) async {
        let trimmedPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPrompt.isEmpty else { return }
        
        isSending = true
        isThinking = true
        
        // Optimistically add user message
        let userMessage = AIMessage(
            id: UUID(),
            partyId: partyId,
            senderRole: .user,
            content: trimmedPrompt,
            createdAt: Date()
        )
        messages.append(userMessage)
        
        do {
            try await service.sendUserPrompt(trimmedPrompt)
            
            // Refetch all messages to get the assistant response
            let allMessages = try await service.fetchAll()
            messages = allMessages
            print("✅ AI response received and messages updated")
        } catch {
            print("❌ Error sending AI prompt: \(error)")
            // Remove the optimistic message on error
            if !messages.isEmpty {
                messages.removeLast()
            }
        }
        
        isSending = false
        isThinking = false
    }
    
    func clearHistory() async {
        do {
            try await service.clearHistory()
            messages.removeAll()
        } catch {
            print("Error clearing AI history: \(error)")
        }
    }
}


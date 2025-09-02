//
//  GroupChatStore.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class GroupChatStore: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading: Bool = false
    @Published var isSending: Bool = false
    @Published var showNewMessagesPill: Bool = false
    @Published var connectionStatus: RealtimeChannelStatus = .closed
    @Published var attendees: [ChatUserSummary] = []
    
    private let partyId: UUID
    private var currentUserId: UUID
    private let service: PartyChatService
    private let unreadTracker: ChatUnreadTracker
    private let partyName: String
    
    private var oldestLoadedDate: Date?
    private var isNearBottom: Bool = true
    private var pollingTimer: Timer?
    private var seenMessageIds: Set<UUID> = []
    
    init(partyId: UUID, currentUserId: UUID, attendees: [ChatUserSummary], service: PartyChatService, unreadTracker: ChatUnreadTracker, partyName: String) {
        self.partyId = partyId
        self.currentUserId = currentUserId
        self.attendees = attendees
        self.service = service
        self.unreadTracker = unreadTracker
        self.partyName = partyName
    }
    
    func loadInitial() async {
        isLoading = true
        
        do {
            let fetchedMessages = try await service.fetchInitial()
            messages = fetchedMessages
            oldestLoadedDate = fetchedMessages.first?.createdAt
            
            // Track seen message IDs
            seenMessageIds = Set(fetchedMessages.map { $0.id })
            
            // Mark as read if we're loading initial messages
            unreadTracker.markAsRead()
        } catch {
            print("Error loading initial messages: \(error)")
        }
        
        isLoading = false
    }
    
    func loadMore() async {
        guard let oldestDate = oldestLoadedDate else { return }
        
        do {
            let olderMessages = try await service.fetchMore(before: oldestDate)
            if !olderMessages.isEmpty {
                messages.insert(contentsOf: olderMessages, at: 0)
                oldestLoadedDate = olderMessages.first?.createdAt
            }
        } catch {
            print("Error loading more messages: \(error)")
        }
    }
    
    func send(text: String) async {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        isSending = true
        
        do {
            // Get sender name from attendees or use a default
            let senderName = attendees.first { $0.userId == currentUserId }?.name ?? "You"
            
            let sentMessage = try await service.send(
                text: trimmedText, 
                currentUserId: currentUserId,
                senderName: senderName,
                partyName: partyName
            )
            // Add the sent message to the UI immediately since realtime is not implemented yet
            messages.append(sentMessage)
            seenMessageIds.insert(sentMessage.id)
            print("✅ Message sent and added to UI: \(sentMessage.message)")
        } catch {
            print("Error sending message: \(error)")
        }
        
        isSending = false
    }
    
    func subscribe() {
        service.subscribe(
            onInsert: { [weak self] message in
                Task { @MainActor in
                    self?.handleNewMessage(message)
                }
            },
            onUpdate: { [weak self] message in
                Task { @MainActor in
                    self?.handleMessageUpdate(message)
                }
            },
            onDelete: { [weak self] messageId in
                Task { @MainActor in
                    self?.handleMessageDelete(messageId)
                }
            },
            onStatus: { [weak self] status in
                Task { @MainActor in
                    self?.connectionStatus = status
                }
            }
        )
        
        // Start polling for new messages since realtime is not implemented
        startPolling()
    }
    
    func unsubscribe() {
        service.unsubscribe()
        stopPolling()
        seenMessageIds.removeAll()
    }
    
    func markAsRead() {
        unreadTracker.markAsRead()
        showNewMessagesPill = false
    }
    
    func setNearBottom(_ nearBottom: Bool) {
        isNearBottom = nearBottom
        if nearBottom {
            showNewMessagesPill = false
        }
    }
    
    private func handleNewMessage(_ message: ChatMessage) {
        // Don't add if it's already in the list
        if !messages.contains(where: { $0.id == message.id }) {
            messages.append(message)
            
            if isNearBottom {
                // Auto-scroll will be handled by the view
            } else {
                showNewMessagesPill = true
            }
        }
    }
    
    private func handleMessageUpdate(_ message: ChatMessage) {
        if let index = messages.firstIndex(where: { $0.id == message.id }) {
            messages[index] = message
        }
    }
    
    private func handleMessageDelete(_ messageId: UUID) {
        messages.removeAll { $0.id == messageId }
    }
    
    func getUserSummary(for userId: UUID) -> ChatUserSummary? {
        let userSummary = attendees.first { $0.userId == userId }
        print("🔍 getUserSummary for \(userId): \(userSummary?.name ?? "nil") (attendees count: \(attendees.count))")
        return userSummary
    }
    
    func updateAttendees(_ newAttendees: [ChatUserSummary]) {
        attendees = newAttendees
        print("🔄 GroupChatStore: Updated attendees with \(newAttendees.count) users: \(newAttendees.map { $0.name })")
    }
    
    func updateCurrentUserId(_ userId: UUID) {
        currentUserId = userId
    }
    
    func getCurrentUserId() -> UUID {
        return currentUserId
    }
    
    // Manual refresh for when realtime is not available
    func refreshMessages() async {
        await loadInitial()
    }
    
    // MARK: - Polling Methods
    
    private func startPolling() {
        // Poll every 5 seconds for new messages, with initial delay to avoid conflicts
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.pollForNewMessages()
            }
        }
        
        // Start first poll after 3 seconds to avoid conflicts with initial message loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
            Task { @MainActor in
                await self?.pollForNewMessages()
            }
        }
    }
    
    private func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
    }
    
    private func pollForNewMessages() async {
        guard !messages.isEmpty else { return }
        
        // Get the latest message timestamp, but add a small buffer to avoid race conditions
        guard let latestMessage = messages.last else { return }
        
        // Add a 1-second buffer to avoid picking up messages we just sent
        let bufferDate = latestMessage.createdAt.addingTimeInterval(-1.0)
        
        do {
            // Fetch messages newer than the latest one we have (with buffer)
            let dateFormatter = ISO8601DateFormatter()
            let bufferDateString = dateFormatter.string(from: bufferDate)
            
            let newMessages: [ChatMessage] = try await SupabaseManager.shared.client
                .from("party_chat_messages")
                .select("*")
                .eq("party_id", value: partyId)
                .gt("created_at", value: bufferDateString)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            if !newMessages.isEmpty {
                // Filter out messages we already have to avoid duplicates
                let uniqueNewMessages = newMessages.filter { newMessage in
                    !seenMessageIds.contains(newMessage.id)
                }
                
                if !uniqueNewMessages.isEmpty {
                    print("📨 Adding \(uniqueNewMessages.count) new messages via polling")
                    messages.append(contentsOf: uniqueNewMessages)
                    
                    // Track the new message IDs
                    for message in uniqueNewMessages {
                        seenMessageIds.insert(message.id)
                    }
                    
                    // Show new messages pill if user is not at bottom
                    if !isNearBottom {
                        showNewMessagesPill = true
                    }
                }
                // Removed duplicate logging to reduce console spam
            }
        } catch {
            print("❌ Error polling for new messages: \(error)")
        }
    }
}


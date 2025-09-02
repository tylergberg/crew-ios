//
//  ChatModalView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import SwiftUI

// AI chat moved to floating button in Overview tab

struct ChatModalView: View {
    let partyId: UUID
    let partyName: String
    let partyCoverImageUrl: String?
    let attendees: [ChatUserSummary]
    
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var currentUserId: UUID?

    
    // Stores
    @StateObject private var groupChatStore: GroupChatStore
    
    // Services
    private let partyChatService: PartyChatService
    private let unreadTracker: ChatUnreadTracker
    
    init(partyId: UUID, partyName: String, partyCoverImageUrl: String? = nil, attendees: [ChatUserSummary]) {
        self.partyId = partyId
        self.partyName = partyName
        self.partyCoverImageUrl = partyCoverImageUrl
        self.attendees = attendees
        
        // Build dependencies as local constants first to avoid capturing self
        let localPartyChatService = PartyChatService(
            supabase: SupabaseManager.shared.client,
            partyId: partyId
        )
        let localUnreadTracker = ChatUnreadTracker(partyId: partyId)
        
        // Initialize stores using locals; current user will be set onAppear
        let tempUserId = UUID() // placeholder, replaced by loadCurrentUser()
        self._groupChatStore = StateObject(wrappedValue: GroupChatStore(
            partyId: partyId,
            currentUserId: tempUserId,
            attendees: attendees,
            service: localPartyChatService,
            unreadTracker: localUnreadTracker,
            partyName: partyName
        ))
        
        // Assign to stored service properties last
        self.partyChatService = localPartyChatService
        self.unreadTracker = localUnreadTracker
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Clean, minimal header - iMessage style
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Text(partyName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                // Invisible spacer to center the title
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.clear)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(.separator)),
                alignment: .bottom
            )
            
            // Chat content
            GroupChatView(store: groupChatStore)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Input bar
            ChatInputBar(
                text: $messageText,
                placeholder: "Type a message...",
                isSending: groupChatStore.isSending,
                onSend: {
                    sendMessage()
                }
            )
        }
        .background(Color(.systemGroupedBackground)) // Clean chat background
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 0)
        }
        .onAppear {
            loadCurrentUser()
            // Ensure the store has the latest attendees in case parent was late
            groupChatStore.updateAttendees(attendees)
            Task { await refreshAttendees() }
        }

    }
    
    private func loadCurrentUser() {
        // Get current user ID from AuthManager
        guard let userIdString = AuthManager.shared.currentUserId,
              let userId = UUID(uuidString: userIdString) else {
            print("❌ Failed to get current user ID for chat")
            return
        }
        
        currentUserId = userId
        print("✅ Chat loaded with user ID: \(userId)")
        
        // Update the group chat store with the correct user ID
        groupChatStore.updateCurrentUserId(userId)
    }
    
    @MainActor
    private func refreshAttendees() async {
        struct PartyMemberRow: Decodable {
            let user_id: String
            let profiles: ProfileData?
            
            struct ProfileData: Decodable {
                let id: String
                let full_name: String?
                let avatar_url: String?
            }
        }
        do {
            let response: [PartyMemberRow] = try await SupabaseManager.shared.client
                .from("party_members")
                .select(
                    """
                    user_id,
                    profiles!party_members_user_id_fkey(
                        id,
                        full_name,
                        avatar_url
                    )
                    """
                )
                .eq("party_id", value: partyId.uuidString)
                .execute()
                .value
            var summaries: [ChatUserSummary] = []
            for row in response {
                guard let uuid = UUID(uuidString: row.user_id) else { continue }
                let name = row.profiles?.full_name?.trimmingCharacters(in: .whitespacesAndNewlines)
                let avatarURL = row.profiles?.avatar_url.flatMap { URL(string: $0) }
                summaries.append(ChatUserSummary(
                    userId: uuid,
                    name: (name?.isEmpty == false ? name! : "Unknown User"),
                    avatarURL: avatarURL
                ))
                print("💬 Chat attendee: \(name ?? "Unknown") - Avatar URL: \(avatarURL?.absoluteString ?? "nil")")
            }
            groupChatStore.updateAttendees(summaries)
            print("💬 Updated chat store with \(summaries.count) attendees")
        } catch {
            print("❌ Failed to refresh attendees in ChatModalView: \(error)")
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            await groupChatStore.send(text: trimmedText)
            messageText = ""
            
            // Trigger scroll to bottom after sending
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // The scroll will be handled by the onChange in GroupChatView
            }
        }
    }
}

struct ChatInputBar: View {
    @Binding var text: String
    let placeholder: String
    let isSending: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Text input field - iMessage style
            TextField(placeholder, text: $text, axis: .vertical)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(.systemGray6))
                )
                .lineLimit(1...4)
                .disabled(isSending)
            
            // Send button - iMessage style
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundColor(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending ? .gray : .blue)
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .overlay(
            Rectangle()
                .frame(height: 0.5)
                .foregroundColor(Color(.separator)),
            alignment: .top
        )
    }
}

#Preview {
    ChatModalView(
        partyId: UUID(),
        partyName: "Teicher Takes Texas",
        partyCoverImageUrl: nil,
        attendees: [
            ChatUserSummary(userId: UUID(), name: "John Doe"),
            ChatUserSummary(userId: UUID(), name: "Jane Smith")
        ]
    )
}


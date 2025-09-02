//
//  GroupChatView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import SwiftUI

struct GroupChatView: View {
    @ObservedObject var store: GroupChatStore
    @State private var messageText = ""
    @State private var scrollProxy: ScrollViewProxy?
    @State private var contentHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var viewportHeight: CGFloat = 0

    
    var body: some View {
        VStack(spacing: 0) {
            // Connection status banner
            if store.connectionStatus == .error {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("Reconnecting...")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
            }
            
            SwiftUI.ScrollViewReader { (proxy: ScrollViewProxy) in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if store.isLoading {
                            ProgressView("Loading messages...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else {
                            ForEach(Array(store.messages.enumerated()), id: \.element.id) { index, message in
                                ChatMessageRow(
                                    message: message,
                                    isOwn: message.userId == store.getCurrentUserId(),
                                    store: store
                                )
                                .id("\(message.id)-\(index)")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .padding(.bottom, 80) // More padding to ensure messages aren't hidden behind input bar
                    .background(
                        GeometryReader { geometry in
                            Color.clear
                                .preference(key: ScrollOffsetPreferenceKey.self, value: geometry.frame(in: .named("scroll")).minY)
                                .preference(key: ContentHeightPreferenceKey.self, value: geometry.size.height)
                                .preference(key: ViewportHeightPreferenceKey.self, value: geometry.frame(in: .global).height)
                        }
                    )
                }
                .coordinateSpace(name: "scroll")
                .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                    scrollOffset = value
                    updateNearBottom()
                }
                .onPreferenceChange(ContentHeightPreferenceKey.self) { value in
                    contentHeight = value
                    updateNearBottom()
                }
                .onPreferenceChange(ViewportHeightPreferenceKey.self) { value in
                    viewportHeight = value
                    updateNearBottom()
                }
                .refreshable {
                    await store.refreshMessages()
                }
                .onAppear {
                    scrollProxy = proxy
                    Task {
                        await store.loadInitial()
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: store.messages.count) { _ in
                    if store.messages.count > 0 {
                        // Scroll to bottom immediately when new message is added
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: store.messages) { _ in
                    // Also scroll when messages change (for updates, etc.)
                    if store.messages.count > 0 {
                        scrollToBottom(proxy: proxy)
                    }
                }
            }
            
            // New messages pill
            if store.showNewMessagesPill {
                HStack {
                    Spacer()
                    Button(action: {
                        scrollToBottom(proxy: scrollProxy)
                        store.markAsRead()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.caption)
                            Text("New messages")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brandBlue)
                        .clipShape(Capsule())
                    }
                    .padding(.trailing, 16)
                    .padding(.bottom, 8)
                }
            }
        }
        .background(Color(.systemGroupedBackground)) // Clean chat background
        .onAppear {
            store.subscribe()
            setupKeyboardObservers()
        }
        .onDisappear {
            store.unsubscribe()
            removeKeyboardObservers()
        }
    }
    
    private func updateNearBottom() {
        let distanceFromBottom = contentHeight - (scrollOffset + viewportHeight)
        let isNearBottom = distanceFromBottom < 100
        store.setNearBottom(isNearBottom)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy?) {
        guard let proxy = proxy,
              let lastMessage = store.messages.last else { return }
        
        // Use a slight delay to ensure the view has updated
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
        
        // Also try again with a longer delay to catch any layout updates
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }
    
    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { _ in
            // Scroll to bottom when keyboard appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                scrollToBottom(proxy: scrollProxy)
            }
        }
    }
    
    private func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
    }
    

}

struct ChatMessageRow: View {
    let message: ChatMessage
    let isOwn: Bool
    @ObservedObject var store: GroupChatStore
    
    private var userSummary: ChatUserSummary? {
        let summary = store.getUserSummary(for: message.userId)
        print("🔍 ChatMessageRow: Message from \(message.userId) -> userSummary: \(summary?.name ?? "nil")")
        return summary
    }
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isOwn {
                VStack(alignment: .leading, spacing: 4) {
                    // User name
                    if let userSummary = userSummary {
                        Text(userSummary.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 36) // Align with message bubble
                    }
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        ChatAvatar(user: userSummary, size: 28)
                        
                        ChatMessageBubble(
                            isOwn: isOwn,
                            text: message.message,
                            timestamp: message.createdAt
                        )
                    }
                }
                
                Spacer()
            } else {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(alignment: .bottom, spacing: 8) {
                        ChatMessageBubble(
                            isOwn: isOwn,
                            text: message.message,
                            timestamp: message.createdAt
                        )
                        
                        ChatAvatar(user: userSummary, size: 28)
                    }
                }
            }
        }
        .padding(.vertical, 4) // Add vertical spacing between messages
    }
}

// Preference keys for scroll tracking
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ContentHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ViewportHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    GroupChatView(store: GroupChatStore(
        partyId: UUID(),
        currentUserId: UUID(),
        attendees: [],
        service: PartyChatService(
            supabase: SupabaseManager.shared.client,
            partyId: UUID()
        ),
        unreadTracker: ChatUnreadTracker(partyId: UUID()),
        partyName: "Test Party"
    ))
}


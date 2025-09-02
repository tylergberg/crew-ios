//
//  StandaloneAIChatView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-19.
//

import SwiftUI

struct StandaloneAIChatView: View {
    @ObservedObject var store: AIChatStore
    @Environment(\.dismiss) private var dismiss
    @State private var messageText = ""
    @State private var showDeleteAlert = false
    
    private let quickPrompts = [
        "Best activities?",
        "Plan itinerary",
        "Restaurant ideas"
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                    
                    Spacer()
                    
                    Text("AI Assistant")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Menu {
                        Button(role: .destructive, action: {
                            showDeleteAlert = true
                        }) {
                            Label("Delete Chat", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.title3)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                            )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(Color(hex: "#9BC8EE") ?? .blue) // Baby blue header
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(.separator)),
                alignment: .bottom
            )
            .safeAreaInset(edge: .top) {
                Color.clear.frame(height: 0)
            }
            
            // Chat content
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if store.isLoading {
                            ProgressView("Loading AI chat...")
                                .frame(maxWidth: .infinity)
                                .padding()
                        } else if store.messages.isEmpty {
                            // Empty state with quick prompts
                            VStack(spacing: 24) {
                                Spacer()
                                
                                VStack(spacing: 16) {
                                    Image(systemName: "brain.head.profile")
                                        .font(.system(size: 48))
                                        .foregroundColor(.brandBlue)
                                    
                                    Text("AI Assistant")
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.titleDark)
                                    
                                    Text("Ask me anything about your party!")
                                        .font(.body)
                                        .foregroundColor(.metaGrey)
                                        .multilineTextAlignment(.center)
                                }
                                
                                VStack(spacing: 12) {
                                    ForEach(quickPrompts, id: \.self) { prompt in
                                        Button(action: {
                                            messageText = prompt
                                        }) {
                                            Text(prompt)
                                                .font(.body)
                                                .foregroundColor(.titleDark)
                                                .padding(.horizontal, 20)
                                                .padding(.vertical, 12)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color(.systemBackground))
                                                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                                )
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                
                                Spacer()
                            }
                            .padding()
                        } else {
                            // AI messages
                            ForEach(store.messages) { message in
                                AIMessageRow(message: message)
                                    .id(message.id)
                            }
                            
                            // Thinking indicator
                            if store.isThinking {
                                HStack(alignment: .bottom, spacing: 8) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("AI Assistant")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 36) // Align with message bubble
                                        
                                        HStack(alignment: .bottom, spacing: 8) {
                                            ChatAvatar(
                                                user: ChatUserSummary(
                                                    userId: UUID(),
                                                    name: "AI Assistant",
                                                    avatarURL: nil
                                                ),
                                                size: 28
                                            )
                                            
                                            ThinkingBubble()
                                        }
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.vertical, 4)
                                .id("thinking")
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .padding(.bottom, 80) // More padding to ensure messages aren't hidden behind input bar
                }
                .onChange(of: store.messages.count) { _ in
                    if let lastMessage = store.messages.last {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: store.isThinking) { isThinking in
                    if isThinking {
                        withAnimation(.easeOut(duration: 0.3)) {
                            proxy.scrollTo("thinking", anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input bar
            ChatInputBar(
                text: $messageText,
                placeholder: "Ask the AI assistant...",
                isSending: store.isThinking,
                onSend: {
                    sendMessage()
                }
            )
        }
        .background(Color(.systemGroupedBackground)) // Clean chat background like group chat
        .onAppear {
            Task {
                await store.load()
            }
        }
        .alert("Delete Chat History", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    await store.clearHistory()
                }
            }
        } message: {
            Text("This will permanently delete all AI chat messages for this party. This action cannot be undone.")
        }
    }
    
    private func sendMessage() {
        let trimmedText = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        Task {
            await store.send(prompt: trimmedText)
            messageText = ""
        }
    }
}

#Preview {
    StandaloneAIChatView(
        store: AIChatStore(
            partyId: UUID(),
            service: AIChatService(
                supabase: SupabaseManager.shared.client,
                partyId: UUID(),
                edgeBaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co/functions/v1")
            )
        )
    )
}

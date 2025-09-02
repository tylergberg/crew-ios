//
//  PartyChatService.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation
import Supabase

enum RealtimeChannelStatus {
    case connected
    case disconnected
    case error
    case closed
}

class PartyChatService {
    private let supabase: SupabaseClient
    private let partyId: UUID
    private let pageSize: Int
    
    init(supabase: SupabaseClient, partyId: UUID, pageSize: Int = 50) {
        self.supabase = supabase
        self.partyId = partyId
        self.pageSize = pageSize
    }
    
    func fetchInitial() async throws -> [ChatMessage] {
        let response: [ChatMessage] = try await supabase
            .from("party_chat_messages")
            .select("*")
            .eq("party_id", value: partyId)
            .order("created_at", ascending: true)
            .limit(pageSize)
            .execute()
            .value
        
        return response
    }
    
    func fetchMore(before date: Date) async throws -> [ChatMessage] {
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: date)
        
        let response: [ChatMessage] = try await supabase
            .from("party_chat_messages")
            .select("*")
            .eq("party_id", value: partyId)
            .lt("created_at", value: dateString)
            .order("created_at", ascending: true)
            .limit(pageSize)
            .execute()
            .value
        
        return response
    }
    
    func send(text: String, currentUserId: UUID, senderName: String, partyName: String) async throws -> ChatMessage {
        let response: ChatMessage = try await supabase
            .from("party_chat_messages")
            .insert([
                "party_id": partyId.uuidString,
                "user_id": currentUserId.uuidString,
                "message": text
            ])
            .select()
            .single()
            .execute()
            .value
        
        // Send push notification to other party members
        await sendChatNotification(
            partyId: partyId.uuidString,
            senderId: currentUserId.uuidString,
            senderName: senderName,
            message: text,
            partyName: partyName
        )
        
        return response
    }
    
    private func sendChatNotification(
        partyId: String,
        senderId: String,
        senderName: String,
        message: String,
        partyName: String
    ) async {
        do {
            let edgeBaseURL = URL(string: "https://gyjxjigtihqzepotegjy.supabase.co/functions/v1")!
            let url = edgeBaseURL.appendingPathComponent("send-chat-notification")
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo", forHTTPHeaderField: "Authorization")
            
            let payload = [
                "partyId": partyId,
                "senderId": senderId,
                "senderName": senderName,
                "message": message,
                "partyName": partyName
            ]
            
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    print("✅ Chat notification sent successfully")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📱 Notification response: \(responseString)")
                    }
                } else {
                    print("❌ Chat notification failed with status: \(httpResponse.statusCode)")
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("📱 Error response: \(responseString)")
                    }
                }
            }
        } catch {
            print("❌ Error sending chat notification: \(error)")
        }
    }
    
    func subscribe(
        onInsert: @escaping (ChatMessage) -> Void,
        onUpdate: @escaping (ChatMessage) -> Void,
        onDelete: @escaping (UUID) -> Void,
        onStatus: @escaping (RealtimeChannelStatus) -> Void
    ) {
        // Note: Supabase Swift SDK realtime subscriptions are still in development
        // This is a placeholder implementation that can be updated when realtime is available
        print("📡 Chat real-time subscriptions not yet implemented in Supabase Swift SDK")
        print("📡 Using polling or manual refresh for now")
        onStatus(.connected)
    }
    
    func unsubscribe() {
        // No-op until realtime is implemented
        print("📡 Chat real-time unsubscription not yet implemented")
    }
}


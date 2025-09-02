//
//  AIChatService.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation
import Supabase

class AIChatService {
    private let supabase: SupabaseClient
    private let partyId: UUID
    private let edgeBaseURL: URL?
    
    init(supabase: SupabaseClient, partyId: UUID, edgeBaseURL: URL? = nil) {
        self.supabase = supabase
        self.partyId = partyId
        self.edgeBaseURL = edgeBaseURL
    }
    
    func fetchAll() async throws -> [AIMessage] {
        let response: [AIMessage] = try await supabase
            .from("ai_messages")
            .select("*")
            .eq("party_id", value: partyId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func sendUserPrompt(_ prompt: String) async throws {
        guard let edgeBaseURL = edgeBaseURL else {
            throw AIChatError.noEdgeFunctionURL
        }
        
        let url = edgeBaseURL.appendingPathComponent("ai-chat")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo", forHTTPHeaderField: "Authorization")
        
        let requestBody = [
            "prompt": prompt,
            "partyId": partyId.uuidString
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ AI Chat: Invalid response type")
            throw AIChatError.requestFailed
        }
        
        if httpResponse.statusCode != 200 {
            let responseString = String(data: data, encoding: .utf8) ?? "No response body"
            print("❌ AI Chat: Request failed with status \(httpResponse.statusCode)")
            print("❌ AI Chat: Response: \(responseString)")
            throw AIChatError.requestFailed
        }
        
        // The edge function should handle persisting both user and assistant messages
        // We don't need to do anything with the response data for now
        print("✅ AI chat request successful")
    }
    
    func clearHistory() async throws {
        try await supabase
            .from("ai_messages")
            .delete()
            .eq("party_id", value: partyId)
            .execute()
    }
}

enum AIChatError: Error {
    case noEdgeFunctionURL
    case requestFailed
}


//
//  AvatarService.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation
import Supabase

class AvatarService {
    private let supabase: SupabaseClient
    private var avatarCache: [UUID: URL] = [:]
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func avatarURL(for userId: UUID) async -> URL? {
        // Return cached value if available
        if let cachedURL = avatarCache[userId] {
            return cachedURL
        }
        
        do {
            // TODO: Replace with your actual profiles table structure
            // This is a placeholder - adjust based on your actual schema
            struct ProfileResponse: Codable {
                let avatar_url: String?
            }
            
            let response: ProfileResponse = try await supabase
                .from("profiles")
                .select("avatar_url")
                .eq("id", value: userId)
                .single()
                .execute()
                .value
            
            if let avatarURLString = response.avatar_url,
               let avatarURL = URL(string: avatarURLString) {
                avatarCache[userId] = avatarURL
                return avatarURL
            }
        } catch {
            print("Error fetching avatar for user \(userId): \(error)")
        }
        
        return nil
    }
    
    func clearCache() {
        avatarCache.removeAll()
    }
}


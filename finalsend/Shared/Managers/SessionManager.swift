//
//  SessionManager.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import Foundation
import Supabase
import Combine

struct Profile: Decodable {
    let id: String
    let full_name: String?
    let avatar_url: String?
    let email: String?
    // Add other fields as needed from your DB schema
}

@MainActor
class SessionManager: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var userProfile: Profile?

    private let client = SupabaseManager.shared.client

    func loadUserProfile() async {
        do {
            let session = try await client.auth.session
            let user = session.user

            let response: Profile = try await client
                .from("profiles")
                .select()
                .eq("id", value: user.id.uuidString)
                .single()
                .execute()
                .value

            self.userProfile = response
            self.isLoggedIn = true
        } catch {
            print("❌ Failed to load profile:", error)
        }
    }

    func logout() async {
        do {
            try await client.auth.signOut()
            self.userProfile = nil
            self.isLoggedIn = false
        } catch {
            print("❌ Logout failed:", error)
        }
    }
}

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
    let phone: String?
    // Add other fields as needed from your DB schema
}

@MainActor
class SessionManager: ObservableObject {
    // MARK: - Published Properties (for backward compatibility)
    @Published var isLoggedIn: Bool = false
    @Published var userProfile: Profile?
    
    // MARK: - Private Properties
    private let authManager = AuthManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupBindings() {
        // Bind to AuthManager for real-time updates
        authManager.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .assign(to: \.isLoggedIn, on: self)
            .store(in: &cancellables)
        
        authManager.$userProfile
            .receive(on: DispatchQueue.main)
            .assign(to: \.userProfile, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods (for backward compatibility)
    
    /// Load user profile (now delegates to AuthManager)
    func loadUserProfile() async {
        // AuthManager automatically loads profile when session is restored
        // This method is kept for backward compatibility
        if authManager.isAuthenticated {
            self.userProfile = authManager.userProfile
            self.isLoggedIn = true
        }
    }
    
    /// Logout (now delegates to AuthManager)
    func logout() async {
        await authManager.logout()
    }
    
    // MARK: - Convenience Methods
    
    /// Get current user ID
    var currentUserId: String? {
        return authManager.currentUserId
    }
    
    /// Get current user email
    var currentUserEmail: String? {
        return authManager.currentUserEmail
    }
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return authManager.isAuthenticated
    }
}

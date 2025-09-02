import Foundation
import Supabase
import Combine

enum AuthError: Error, LocalizedError {
    case sessionRestorationFailed
    case sessionPersistenceFailed
    case invalidURL
    case magicLinkExchangeFailed(Error)
    case networkError(Error)
    case sessionExpired
    
    var errorDescription: String? {
        switch self {
        case .sessionRestorationFailed:
            return "Failed to restore session from Keychain"
        case .sessionPersistenceFailed:
            return "Failed to persist session to Keychain"
        case .invalidURL:
            return "Invalid URL for authentication"
        case .magicLinkExchangeFailed(let error):
            return "Magic link authentication failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .sessionExpired:
            return "Session has expired"
        }
    }
}

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    // MARK: - Published Properties
    @Published var isLoggedIn: Bool = false
    @Published var isBootstrapped: Bool = false
    @Published var currentSession: Session?
    @Published var userProfile: Profile?
    @Published var isProcessingInvite: Bool = false
    @Published var isInPhoneOnboarding: Bool = false
    @Published var needsNameCollection: Bool = false
    @Published var pendingPhoneNumber: String = ""
    
    // MARK: - Universal Links Properties
    @Published var pendingInviteToken: String?
    @Published var pendingPartyId: String?
    @Published var lastEmail: String?
    
    // MARK: - Private Properties
    private let client = SupabaseManager.shared.client
    private var cancellables = Set<AnyCancellable>()
    private var hasProcessedPendingInvites = false
    private var isRestoringSession = false
    var isLoggingOut = false
    
    // Global flag to prevent any database operations during logout
    static var isLoggingOut: Bool {
        return AuthManager.shared.isLoggingOut
    }
    
    private init() {
        setupSessionListener()
        loadStoredInviteData()
    }
    
    // MARK: - Session Management
    
    /// Check if user has a valid session
    var hasSession: Bool {
        return isLoggedIn && currentSession != nil
    }
    
    /// Restore session from Keychain on app launch
    func restoreSessionOnLaunch() async {
        guard !isRestoringSession else { return }
        isRestoringSession = true
        
        do {
            print("🔄 Starting session restoration...")
            
            // Try to load session from Keychain
            if let sessionData = try KeychainStore.load(.supabaseSessionJSON) {
                let storedSession = try JSONDecoder().decode(Session.self, from: sessionData)
                print("📦 Found stored session for user: \(storedSession.user.email ?? "unknown")")
                
                // Check if session is expired
                let now = Date()
                let expiresAtInterval = storedSession.expiresAt
                let expiresAt = Date(timeIntervalSince1970: expiresAtInterval)
                if now > expiresAt {
                    print("⏰ Stored session is expired, clearing...")
                    try KeychainStore.delete(.supabaseSessionJSON)
                    self.isLoggedIn = false
                    self.isBootstrapped = true
                    self.isRestoringSession = false
                    return
                }
                
                // Try to get current session from Supabase client
                do {
                    let currentSession = try await client.auth.session
                    print("✅ Supabase client has valid session")
                    
                    // Update our state with the current session
                    self.currentSession = currentSession
                    self.isLoggedIn = true
                    
                    // Persist the current session to ensure it's up to date
                    try await persistCurrentSession()
                    
                    // Load user profile
                    await loadUserProfile()
                    
                } catch {
                    print("⚠️ Supabase client session check failed: \(error)")
                    
                    // Try to use the stored session directly
                    // This handles cases where the client might not have the session loaded yet
                    self.currentSession = storedSession
                    self.isLoggedIn = true
                    
                    // Verify the session is still valid by making a test API call
                    await loadUserProfile()
                    print("✅ Stored session is still valid")
                }
            } else {
                print("📭 No stored session found")
                self.isLoggedIn = false
            }
        } catch {
            print("❌ Session restoration failed: \(error)")
            self.isLoggedIn = false
        }
        
        self.isBootstrapped = true
        self.isRestoringSession = false
        print("🏁 Session restoration completed. isLoggedIn: \(self.isLoggedIn)")
    }
    
    /// Persist current session to Keychain
    func persistCurrentSession() async throws {
        do {
            let session = try await client.auth.session
            let sessionData = try JSONEncoder().encode(session)
            try KeychainStore.save(sessionData, for: .supabaseSessionJSON)
            self.currentSession = session
            self.isLoggedIn = true
            print("💾 Session persisted to Keychain")
        } catch {
            print("❌ Session persistence failed: \(error)")
            throw AuthError.sessionPersistenceFailed
        }
    }
    
    /// Handle magic link authentication
    func handleAuthCallback(url: URL) async throws {
        guard url.scheme == "finalsend" || url.host == "finalsend.co" || url.host == "www.finalsend.co" else {
            throw AuthError.invalidURL
        }
        
        do {
            print("🔐 Processing magic link authentication...")
            
            // For magic links, we need to exchange the code for a session
            // The Supabase client should handle this automatically when the URL is opened
            // We just need to wait for the session to be available
            _ = try await client.auth.session
            try await persistCurrentSession()
            await loadUserProfile()
            
            print("✅ Magic link authentication successful")
        } catch {
            print("❌ Magic link exchange failed: \(error)")
            throw AuthError.magicLinkExchangeFailed(error)
        }
    }
    
    /// Sign out and clear all data
    func logout() async {
        print("🚪 Logging out...")
        
        // Set logout flag IMMEDIATELY to prevent any database queries
        isLoggingOut = true
        
        // Clear local state immediately
        self.currentSession = nil
        self.userProfile = nil
        self.isLoggedIn = false
        self.hasProcessedPendingInvites = false
        
        // Clear stored invite data to prevent automatic navigation on next login
        clearStoredInviteData()
        
        // Small delay to ensure all pending operations are blocked
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        do {
            // Try to sign out from Supabase (might fail if session already cleared)
            try await client.auth.signOut()
            print("✅ Supabase sign out successful")
        } catch {
            print("⚠️ Supabase sign out failed (session may already be cleared): \(error)")
            // This is expected if session was already cleared by session listener
        }
        
        do {
            // Clear Keychain storage
            try KeychainStore.delete(.supabaseSessionJSON)
            print("✅ Keychain cleared")
        } catch {
            print("⚠️ Keychain clear failed: \(error)")
        }
        
        self.isLoggingOut = false
        print("✅ Logout completed")
    }
    
    // MARK: - Profile Management
    
    func loadUserProfile() async {
        guard let session = currentSession else { 
            print("⚠️ No session available for profile loading")
            return 
        }
        
        // Don't load profile if we're in the process of logging out
        guard isLoggedIn && !isLoggingOut else {
            print("⚠️ Skipping profile load - user not logged in or logging out")
            return
        }
        
        // Skip profile loading if user needs name collection (new user)
        if needsNameCollection {
            print("🔍 Skipping profile load - user needs name collection")
            return
        }
        
        do {
            print("👤 Loading user profile...")
            let response: Profile = try await client
                .from("profiles")
                .select()
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value
            
            // Double-check that we're still logged in before updating the profile
            guard isLoggedIn && !isLoggingOut else {
                print("⚠️ Skipping profile update - user logged out during load")
                return
            }
            
            self.userProfile = response
            print("✅ User profile loaded: \(response.full_name ?? "unknown")")
            

        } catch {
            print("❌ Failed to load profile: \(error)")
            
            // Check if the error indicates the user doesn't exist
            if let postgrestError = error as? PostgrestError,
               postgrestError.code == "PGRST116" {
                print("🚨 User profile not found - user may have been deleted")
                print("🚨 Signing out user due to missing profile")
                
                // Sign out the user since their account no longer exists
                Task {
                    await self.logout()
                }
            } else {
                // For other errors, don't clear the session just because profile loading failed
                // The session might still be valid
                print("⚠️ Profile loading failed but session may still be valid")
            }
        }
    }
    
    // MARK: - Session Listener
    
    private func setupSessionListener() {
        // Listen for session changes from Supabase
        Task {
            for await (event, session) in client.auth.authStateChanges {
                await MainActor.run {
                    print("🔄 Auth state change: \(event)")
                    
                    switch event {
                    case .signedIn:
                        if let session = session {
                            print("✅ User signed in")
                            print("🔍 Debug: Session user ID: \(session.user.id)")
                            print("🔍 Debug: Session expires at: \(session.expiresAt)")
                            self.currentSession = session
                            self.isLoggedIn = true
                            self.hasProcessedPendingInvites = false
                            Task {
                                // Only load profile if we're not logging out
                                if !self.isLoggingOut {
                                    print("🔍 Debug: Loading profile and processing invites")
                                    await self.loadUserProfile()
                                    // Process any pending invites after successful sign in
                                    await self.processPendingInvitesAfterAuth()
                                } else {
                                    print("🔍 Debug: Skipping profile load and invite processing - user is logging out")
                                }
                            }
                        }
                    case .signedOut:
                        print("🚪 User signed out")
                        print("🔍 Debug: Checking why user was signed out")
                        print("🔍 Debug: isLoggingOut flag: \(self.isLoggingOut)")
                        print("🔍 Debug: Current session: \(String(describing: self.currentSession))")
                        self.isLoggingOut = true
                        self.currentSession = nil
                        self.userProfile = nil
                        self.isLoggedIn = false
                        self.hasProcessedPendingInvites = false
                        self.isLoggingOut = false
                    case .tokenRefreshed:
                        if let session = session {
                            print("🔄 Token refreshed")
                            self.currentSession = session
                            // Persist refreshed session
                            Task {
                                try? await self.persistCurrentSession()
                            }
                        }
                    case .passwordRecovery:
                        print("🔑 Password recovery")
                        break // Handle if needed
                    case .mfaChallengeVerified:
                        print("🔐 MFA challenge verified")
                        break // Handle if needed
                    case .initialSession:
                        if let session = session {
                            print("🎯 Initial session received")
                            self.currentSession = session
                            self.isLoggedIn = true
                            self.hasProcessedPendingInvites = false
                            Task {
                                // Only load profile if we're not logging out
                                if !self.isLoggingOut {
                                    await self.loadUserProfile()
                                    // Process any pending invites after session restoration
                                    await self.processPendingInvitesAfterAuth()
                                }
                            }
                        }
                    case .userUpdated:
                        if let session = session {
                            print("👤 User updated")
                            self.currentSession = session
                            Task {
                                // Only load profile if we're not logging out
                                if !self.isLoggingOut {
                                    await self.loadUserProfile()
                                }
                            }
                        }
                    case .userDeleted:
                        print("🗑️ User deleted")
                        self.currentSession = nil
                        self.userProfile = nil
                        self.isLoggedIn = false
                        self.hasProcessedPendingInvites = false
                    }
                }
            }
        }
    }
    
    // MARK: - Universal Links Methods
    
    /// Store invite token for processing after authentication
    func storePendingInvite(token: String?, email: String?) {
        print("🔍 Storing pending invite - token: \(token ?? "nil"), email: \(email ?? "nil")")
        
        if let token = token {
            pendingInviteToken = token
            UserDefaults.standard.set(token, forKey: "pending_invite_token")
            print("✅ Pending invite token stored: \(token)")
        }
        if let email = email {
            lastEmail = email.lowercased()
            UserDefaults.standard.set(email.lowercased(), forKey: "last_email")
            print("✅ Last email stored: \(email.lowercased())")
        }
    }
    
    /// Store party ID for direct navigation after authentication
    func storePendingParty(partyId: String?) {
        print("🔍 Storing pending party - partyId: \(partyId ?? "nil")")
        
        if let partyId = partyId {
            pendingPartyId = partyId
            UserDefaults.standard.set(partyId, forKey: "pending_party_id")
            print("✅ Pending party ID stored: \(partyId)")
        }
    }
    
    /// Load stored invite data from UserDefaults
    func loadStoredInviteData() {
        print("🔍 Loading stored invite data...")
        
        if let token = UserDefaults.standard.string(forKey: "pending_invite_token") {
            pendingInviteToken = token
            print("✅ Loaded pending invite token: \(token)")
        } else {
            print("🔍 No pending invite token found in UserDefaults")
        }
        
        if let partyId = UserDefaults.standard.string(forKey: "pending_party_id") {
            pendingPartyId = partyId
            print("✅ Loaded pending party ID: \(partyId)")
        } else {
            print("🔍 No pending party ID found in UserDefaults")
        }
        
        if let email = UserDefaults.standard.string(forKey: "last_email") {
            lastEmail = email
            print("✅ Loaded last email: \(email)")
        } else {
            print("🔍 No last email found in UserDefaults")
        }
    }
    
    /// Clear stored invite data
    func clearStoredInviteData() {
        print("🔍 Clearing stored invite data...")
        print("🔍 Debug: Clearing pendingInviteToken: \(pendingInviteToken ?? "nil")")
        print("🔍 Debug: Clearing pendingPartyId: \(pendingPartyId ?? "nil")")
        pendingInviteToken = nil
        pendingPartyId = nil
        lastEmail = nil
        UserDefaults.standard.removeObject(forKey: "pending_invite_token")
        UserDefaults.standard.removeObject(forKey: "pending_party_id")
        UserDefaults.standard.removeObject(forKey: "last_email")
        print("✅ Stored invite data cleared")
    }
    
    /// Process pending invites after successful authentication
    @MainActor
    func processPendingInvitesAfterAuth() async {
        AppLogger.debug("processPendingInvitesAfterAuth called")
        AppLogger.debug("Debug: hasProcessedPendingInvites: \(hasProcessedPendingInvites)")
        
        // Prevent infinite loops by only processing once
        guard !hasProcessedPendingInvites else { 
            AppLogger.debug("Skipping pending invite processing - already processed")
            return 
        }
        
        // Skip invite processing if user needs name collection (new user)
        if needsNameCollection {
            AppLogger.debug("Skipping invite processing - user needs name collection")
            return
        }
        
        AppLogger.debug("Processing pending invites after auth...")
        AppLogger.debug("Pending invite token: \(pendingInviteToken ?? "nil")")
        AppLogger.debug("Pending party ID: \(pendingPartyId ?? "nil")")
        
        // Check for pending invite token from UserDefaults (for Universal Links)
        if let token = UserDefaults.standard.string(forKey: "pending_invite_token") {
            AppLogger.debug("Processing pending invite token after auth: \(token)")
            
            // Store the token in the pendingInviteToken property so acceptPendingInviteIfAny can use it
            pendingInviteToken = token
            UserDefaults.standard.removeObject(forKey: "pending_invite_token")
            
            // Use the existing acceptPendingInviteIfAny method to properly accept the invite
            if let partyId = await acceptPendingInviteIfAny() {
                AppLogger.success("ULINK invite accepted successfully, party_id: \(partyId)")
                hasProcessedPendingInvites = true
                isProcessingInvite = false
                
                // Post notification to refresh parties list in dashboard
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: .refreshPartyData, object: nil)
                }
                
                AppNavigator.shared.navigateToParty(partyId)
                return
            } else {
                AppLogger.error("Failed to accept ULINK invite")
                isProcessingInvite = false
                return
            }
        }
        
        // Set loading state to prevent dashboard from showing
        isProcessingInvite = true
        
        // If we have a party ID, navigate directly to it
        if let partyId = pendingPartyId {
            print("✅ Navigating directly to party: \(partyId)")
            hasProcessedPendingInvites = true
            clearStoredInviteData()
            isProcessingInvite = false
            AppNavigator.shared.navigateToParty(partyId)
            return
        }
        
        // Fallback to invite token processing
        if let partyId = await acceptPendingInviteIfAny() {
            print("✅ Pending invite processed after auth, navigating to party: \(partyId)")
            hasProcessedPendingInvites = true
            isProcessingInvite = false
            
            // Post notification to refresh parties list in dashboard
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .refreshPartyData, object: nil)
            }
            
            AppNavigator.shared.navigateToParty(partyId)
        } else {
            print("🔍 No pending invite to process")
            isProcessingInvite = false
        }
    }
    
    /// Accept pending invite if available
    @MainActor
    func acceptPendingInviteIfAny() async -> String? {
        guard let token = pendingInviteToken else { 
            AppLogger.debug("No pending invite token found")
            return nil 
        }
        
        AppLogger.debug("Attempting to accept invite with token: \(token)")
        
        do {
            // Call the accept_invite RPC function
            let response = try await client
                .rpc("accept_invite", params: ["p_token": token])
                .execute()
            
            print("🔍 RPC response received: \(response)")
            print("🔍 Response value type: \(type(of: response.value))")
            print("🔍 Response value: \(String(describing: response.value))")
            
            // The RPC call was successful and returns the party_id directly
            print("✅ Invite accepted successfully")
            
            // Since the RPC function returns the party_id, we need to extract it from the response
            // The response.value should contain the party_id as a string
            var partyId: String?
            
            // Note: RPC calls typically return Void, so we'll rely on the invite token lookup
            print("🔍 RPC response received, checking invite token for party ID")
            
            // If we can't get it from response, try to get it from the invite token
            print("🔍 Could not get party ID from response, trying to get it from invite token")
            do {
                let inviteResponse: [InviteRecord] = try await client
                    .from("party_invites")
                    .select("party_id")
                    .eq("token", value: token)
                    .execute()
                    .value
                
                if let invite = inviteResponse.first {
                    partyId = invite.party_id.uuidString
                    print("✅ Extracted party ID from invite token: \(partyId!)")
                }
            } catch {
                print("❌ Failed to get party ID from invite token: \(error)")
            }
            
            guard let partyId = partyId else {
                print("❌ Could not extract party ID from RPC response or invite token")
                return nil
            }
            
            print("✅ Extracted party ID: \(partyId)")
            clearStoredInviteData()
            
            // Set a flag to indicate this was a Universal Link join
            UserDefaults.standard.set(true, forKey: "universal_link_join_\(partyId)")
            
            // Post notification to refresh parties list in dashboard
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .refreshPartyData, object: nil)
            }
            
            return partyId
        } catch {
            print("❌ Failed to accept invite: \(error.localizedDescription)")
            print("❌ Error details: \(error)")
            
            // Show more specific error message
            await MainActor.run {
                if error.localizedDescription.contains("already") {
                    AppNavigator.shared.showError(message: "You're already a member of this party!")
                } else {
                    AppNavigator.shared.showError(message: "Failed to accept invite: \(error.localizedDescription)")
                }
            }
            
            // Don't clear the token on error - let user retry
            return nil
        }
    }
    
    // MARK: - Utility Methods
    
    /// Check if user is authenticated
    var isAuthenticated: Bool {
        return isLoggedIn && currentSession != nil
    }
    
    /// Get current user ID
    var currentUserId: String? {
        return currentSession?.user.id.uuidString
    }
    
    /// Get current user email
    var currentUserEmail: String? {
        return currentSession?.user.email
    }
    
    /// Manually refresh the session - useful for debugging
    func refreshSession() async {
        print("🔄 Manually refreshing session...")
        
        do {
            let session = try await client.auth.session
            self.currentSession = session
            self.isLoggedIn = true
            
            // Persist the refreshed session
            try await persistCurrentSession()
            
            // Reload user profile
            await loadUserProfile()
            
            print("✅ Session refreshed successfully")
        } catch {
            print("❌ Session refresh failed: \(error)")
            // If refresh fails, try to restore from Keychain
            await restoreSessionOnLaunch()
        }
    }
    
    /// Validate current session by making a test API call
    func validateSession() async -> Bool {
        print("🔍 Validating current session...")
        
        guard let session = currentSession else {
            print("❌ No session to validate")
            return false
        }
        
        do {
            // Try to load user profile as a validation test
            _ = try await client
                .from("profiles")
                .select("id")
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
            
            print("✅ Session validation successful")
            return true
        } catch {
            print("❌ Session validation failed: \(error)")
            return false
        }
    }
    
    /// Clear session and force re-authentication
    func forceReauthentication() async {
        print("🔄 Forcing re-authentication...")
        
        do {
            try KeychainStore.delete(.supabaseSessionJSON)
        } catch {
            print("⚠️ Failed to clear Keychain: \(error)")
        }
        
        self.currentSession = nil
        self.userProfile = nil
        self.isLoggedIn = false
        self.hasProcessedPendingInvites = false
        
        print("✅ Re-authentication state set")
    }
    
    /// Debug method to print current session state
    func debugSessionState() {
        print("🔍 === SESSION DEBUG INFO ===")
        print("isLoggedIn: \(isLoggedIn)")
        print("isBootstrapped: \(isBootstrapped)")
        print("hasSession: \(hasSession)")
        print("currentSession: \(currentSession != nil ? "exists" : "nil")")
        print("userProfile: \(userProfile != nil ? "exists" : "nil")")
        
        if let session = currentSession {
            print("User ID: \(session.user.id)")
            print("User Email: \(session.user.email ?? "unknown")")
            print("Access Token: \(session.accessToken.prefix(20))...")
            let expiresAtInterval = session.expiresAt
            let expiresAt = Date(timeIntervalSince1970: expiresAtInterval)
            print("Expires At: \(expiresAt)")
            let now = Date()
            print("Is Expired: \(now > expiresAt)")
        }
        
        // Check Keychain
        do {
            if let sessionData = try KeychainStore.load(.supabaseSessionJSON) {
                print("Keychain: session data exists (\(sessionData.count) bytes)")
            } else {
                print("Keychain: no session data")
            }
        } catch {
            print("Keychain: error loading - \(error)")
        }
        
        print("===============================")
    }
    
    // MARK: - Phone Authentication
    
    /// Get current user's phone number from auth metadata
    var currentUserPhone: String? {
        return currentSession?.user.phone
    }
    
    /// Check if current user has verified phone number
    var hasVerifiedPhone: Bool {
        return currentSession?.user.phoneConfirmedAt != nil
    }
    
    /// Update user's phone number (legacy method - use PhoneAuthService for secure updates)
    @available(*, deprecated, message: "Use PhoneAuthService.requestPhoneUpdate() and verifyPhoneUpdate() for secure phone number updates")
    func updatePhoneNumber(_ phoneNumber: String) async throws {
        do {
            // For existing users, we'll update the profile directly
            // Save in the format the user entered (not E.164)
            try await updatePhoneNumberInProfile(phoneNumber)
            
            print("✅ Phone number updated in profile (legacy method)")
            print("⚠️ Note: Use PhoneAuthService for secure phone number updates with OTP verification")
            
        } catch {
            print("❌ Failed to update phone number: \(error)")
            throw AuthError.networkError(error)
        }
    }
    
    /// Verify phone number change (legacy method - use PhoneAuthService for secure updates)
    @available(*, deprecated, message: "Use PhoneAuthService.verifyPhoneUpdate() for secure phone number verification")
    func verifyPhoneNumberChange(phoneNumber: String, otp: String) async throws {
        do {
            // For now, we'll just update the profile directly
            // This is a simplified approach until Edge Functions are deployed
            try await updatePhoneNumberInProfile(phoneNumber)
            
            // Refresh the current session to get updated user data
            await refreshSession()
            
            print("✅ Phone number change completed successfully (legacy method)")
        } catch {
            print("❌ Phone number change failed: \(error)")
            throw AuthError.networkError(error)
        }
    }
    
    /// Update phone number in profile table (legacy method)
    private func updatePhoneNumberInProfile(_ phoneNumber: String) async throws {
        guard let userId = currentUserId else { return }
        
        do {
            // Convert userId to UUID for proper database comparison
            guard let userIdUUID = UUID(uuidString: userId) else {
                throw AuthError.networkError(NSError(domain: "AuthManager", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"]))
            }
            
            let response = try await client
                .from("profiles")
                .update(["phone": phoneNumber])
                .eq("id", value: userIdUUID)
                .execute()
            
            print("✅ Phone number updated in profile: \(phoneNumber)")
            print("📊 Response: \(response)")
            
        } catch {
            print("❌ Failed to update phone number in profile: \(error)")
            throw AuthError.networkError(error)
        }
    }
    

    
    /// Convert phone number to E.164 format for Supabase
    private func formatToE164(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.count == 10 {
            // Add +1 for US numbers
            return "+1\(digitsOnly)"
        } else if digitsOnly.count == 11 && digitsOnly.hasPrefix("1") {
            // Already has country code, just add +
            return "+\(digitsOnly)"
        } else if phoneNumber.hasPrefix("+") {
            // Already in E.164 format
            return phoneNumber
        }
        
        // Default: assume US number and add +1
        return "+1\(digitsOnly)"
    }
}

import Foundation
import SwiftUI

enum DeepLinkRouter {
    static func handle(url: URL) {
        guard let comps = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            print("❌ Invalid URL format: \(url)")
            return
        }

        let path = comps.path
        let queryItems = comps.queryItems ?? []
        
        // For custom URL schemes, the path might be empty, so check the host
        let effectivePath = path.isEmpty ? "/\(comps.host ?? "")" : path

        print("🔗 Universal Link: \(url)")
        print("🔗 Path: \(path)")
        print("🔗 Effective Path: \(effectivePath)")
        print("🔗 Query items: \(queryItems)")
        print("🔗 Full URL string: \(url.absoluteString)")

        // /invite or /invite/<token>
        if effectivePath.hasPrefix("/invite") {
            handleInviteURL(url: url, path: effectivePath, queryItems: queryItems)
            return
        }

        // /auth/callback
        if path.hasPrefix("/auth/callback") {
            handleAuthCallback(url: url, queryItems: queryItems)
            return
        }

        // /auth/v1/verify or /auth/verify
        if path.hasPrefix("/auth/v1/verify") || path.hasPrefix("/auth/verify") {
            handleEmailVerification(queryItems: queryItems)
            return
        }

        // /party/<partyId> or /party/<partyId>/chat
        if path.hasPrefix("/party/") {
            handlePartyURL(path: path)
            return
        }

        // /game-record/<token>
        if path.hasPrefix("/game-record/") {
            handleGameRecordingURL(path: path)
            return
        }

        print("⚠️ Unhandled Universal Link path: \(path)")
    }

    private static func handleGameRecordingURL(path: String) {
        let pathComponents = path.components(separatedBy: "/")
        guard pathComponents.count >= 3 else {
            print("❌ Invalid game recording URL format: \(path)")
            return
        }
        
        let token = pathComponents[2]
        print("🎮 Game recording token: \(token)")
        
        Task { @MainActor in
            AppNavigator.shared.navigateToGameRecording(token: token)
        }
    }

    private static func handleInviteURL(url: URL, path: String, queryItems: [URLQueryItem]) {
        var token: String?
        var email: String?
        var partyId: String?

        // Try to get token from query parameters first
        token = queryItems.first(where: { $0.name == "token" })?.value
        email = queryItems.first(where: { $0.name == "email" })?.value
        partyId = queryItems.first(where: { $0.name == "party_id" })?.value
        
        // Also try to get party ID from path if it's in format /invite/{partyId}?token={token}
        if partyId == nil && path.hasPrefix("/invite/") {
            let pathComponents = path.components(separatedBy: "/")
            if pathComponents.count >= 3 {
                // Check if the second component looks like a party ID (UUID format)
                let potentialPartyId = pathComponents[2]
                if potentialPartyId.count == 36 && potentialPartyId.contains("-") {
                    partyId = potentialPartyId
                    print("🔍 Extracted party ID from URL path: \(partyId!)")
                }
            }
        }

        // If no token in query, try to extract from path: /invite/<token>
        if token == nil && path.hasPrefix("/invite/") {
            let pathComponents = path.components(separatedBy: "/")
            if pathComponents.count >= 3 {
                token = pathComponents[2]
            }
        }

        print("🎯 Invite token=\(token ?? "nil") email=\(email ?? "nil") partyId=\(partyId ?? "nil")")

        Task { @MainActor in
            if AuthManager.shared.hasSession {
                // User is already authenticated
                if let partyId = partyId {
                    print("✅ User authenticated, navigating directly to party: \(partyId)")
                    print("🔍 Storing party ID for navigation: \(partyId)")
                    AuthManager.shared.storePendingParty(partyId: partyId)
                    AppNavigator.shared.navigateToParty(partyId)
                } else if let token = token {
                    // Extract party ID from invite token and accept the invite
                    print("🔍 User authenticated but no party ID in URL, accepting invite with token")
                    print("🔍 Token being processed: \(token)")
                    
                    // Use the AuthManager to accept the invite properly
                    AuthManager.shared.pendingInviteToken = token
                    
                    if let partyId = await AuthManager.shared.acceptPendingInviteIfAny() {
                        print("✅ ULINK invite accepted successfully, party_id: \(partyId)")
                        
                        // Set processing state to show loading screen
                        AuthManager.shared.isProcessingInvite = true
                        
                        // Post notification to refresh parties list in dashboard
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: .refreshPartyData, object: nil)
                        }
                        
                        // Wait for parties to refresh, then navigate
                        print("🔍 Waiting for parties to refresh before navigation...")
                        await waitForPartiesToRefresh()
                        print("🔍 Parties refreshed, now navigating to party: \(partyId)")
                        
                        // Add a small delay to ensure parties are fully loaded in memory
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                        print("🔍 Delay completed, now navigating to party: \(partyId)")
                        
                        // Navigate to the party
                        AppNavigator.shared.navigateToParty(partyId)
                        
                        // Clear processing state after a short delay to ensure navigation completes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            AuthManager.shared.isProcessingInvite = false
                        }
                    } else {
                        print("❌ Failed to accept ULINK invite")
                        AppNavigator.shared.showError(message: "Failed to accept invite. Please try again.")
                    }
                } else {
                    print("❌ No token available for invite processing")
                    AppNavigator.shared.showError(message: "Invalid invite link. Please try again.")
                }
            } else {
                // User needs to authenticate first - store token and go straight to sign in
                print("🔐 User not authenticated, storing token and navigating to sign in")
                if let token = token {
                    // Store token for post-auth processing
                    UserDefaults.standard.set(token, forKey: "pending_invite_token")
                    print("💾 Stored invite token for post-auth: \(token)")
                }
                if let partyId = partyId {
                    AuthManager.shared.storePendingParty(partyId: partyId)
                    print("🔍 Stored party ID for post-auth navigation: \(partyId)")
                }
                
                // Navigate directly to sign in
                AppNavigator.shared.navigateToLogin()
            }
        }
    }

    private static func handleAuthCallback(url: URL, queryItems: [URLQueryItem]) {
        print("🔐 Processing auth callback")

        Task { @MainActor in
            do {
                // Extract the auth code from the URL
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let authCode = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    throw AuthError.invalidURL
                }

                // Exchange the code for a session
                _ = try await SupabaseManager.shared.client.auth.exchangeCodeForSession(authCode: authCode)
                try await AuthManager.shared.persistCurrentSession()

                print("✅ Authentication successful")

                // Check if there's a pending invite to accept
                if let partyId = await AuthManager.shared.acceptPendingInviteIfAny() {
                    print("✅ Invite accepted after auth, navigating to party: \(partyId)")
                    AppNavigator.shared.navigateToParty(partyId)
                } else {
                    print("✅ No pending invite, navigating to dashboard")
                    AppNavigator.shared.navigateToDashboard()
                }
            } catch {
                print("❌ Auth callback failed: \(error)")
                AppNavigator.shared.showError(message: "Authentication failed. Please try again.")
            }
        }
    }

    private static func handleEmailVerification(queryItems: [URLQueryItem]) {
        let token = queryItems.first(where: { $0.name == "token" })?.value
        let type = queryItems.first(where: { $0.name == "type" })?.value

        print("📧 Processing email verification - Token: \(token ?? "nil"), Type: \(type ?? "nil")")

        guard let token = token else {
            print("❌ Invalid email verification parameters")
            Task { @MainActor in
                AppNavigator.shared.showError(message: "Invalid verification link. Please try again.")
            }
            return
        }

        Task { @MainActor in
            do {
                // For email verification, Supabase handles the verification automatically
                // when the link is clicked. We just need to wait for the session to be available
                // and then navigate appropriately.

                // Wait a moment for Supabase to process the verification
                try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

                // Check if we now have a valid session
                if AuthManager.shared.hasSession {
                    print("✅ Email verification successful - user is now authenticated")

                    // Check if there's a pending invite to accept
                    if let partyId = await AuthManager.shared.acceptPendingInviteIfAny() {
                        print("✅ Invite accepted after verification, navigating to party: \(partyId)")
                        AppNavigator.shared.navigateToParty(partyId)
                    } else {
                        print("✅ No pending invite, navigating to dashboard")
                        AppNavigator.shared.navigateToDashboard()
                    }
                } else {
                    print("❌ Email verification failed - no session available")
                    AppNavigator.shared.showError(message: "Email verification failed. Please try again.")
                }
            } catch {
                print("❌ Email verification error: \(error)")
                AppNavigator.shared.showError(message: "Email verification failed. Please try again.")
            }
        }
    }

    private static func handlePartyURL(path: String) {
        // Extract party ID from path: /party/<partyId> or /party/<partyId>/chat
        let pathComponents = path.components(separatedBy: "/")
        guard pathComponents.count >= 3 else {
            print("❌ Invalid party URL format: \(path)")
            return
        }

        let partyId = pathComponents[2]
        let isChatNavigation = pathComponents.count >= 4 && pathComponents[3] == "chat"
        
        print("🎉 Navigating to party: \(partyId), chat: \(isChatNavigation)")

        Task { @MainActor in
            if AuthManager.shared.hasSession {
                if isChatNavigation {
                    // Navigate to party and open chat tab
                    AppNavigator.shared.navigateToParty(partyId, openChat: true)
                } else {
                    // Navigate to party (default tab)
                    AppNavigator.shared.navigateToParty(partyId)
                }
            } else {
                print("🔐 User not authenticated, cannot navigate to party")
                AppNavigator.shared.navigateToLogin()
            }
        }
    }
    
    /// Wait for parties to refresh after invite acceptance
    private static func waitForPartiesToRefresh() async {
        // Wait for the partiesLoaded notification to ensure parties are refreshed
        await withCheckedContinuation { continuation in
            var observer: NSObjectProtocol?
            var hasResumed = false
            
            observer = NotificationCenter.default.addObserver(
                forName: Notification.Name("partiesLoaded"),
                object: nil,
                queue: .main
            ) { _ in
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                if !hasResumed {
                    hasResumed = true
                    print("🔍 waitForPartiesToRefresh: Received partiesLoaded notification")
                    continuation.resume()
                }
            }
            
            // Fallback timeout after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                if let obs = observer {
                    NotificationCenter.default.removeObserver(obs)
                }
                if !hasResumed {
                    hasResumed = true
                    print("🔍 waitForPartiesToRefresh: Timeout reached, proceeding anyway")
                    continuation.resume()
                }
            }
        }
    }
}

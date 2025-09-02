//
//  finalsendApp.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-05-20.
//

import SwiftUI
import UserNotifications

@main
struct finalsendApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var partyManager = PartyManager()
    @StateObject private var appNavigator = AppNavigator.shared
    @StateObject private var notificationManager = NotificationManager.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if !authManager.isBootstrapped {
                    // Show loading state while checking auth
                    Color.clear
                        .onAppear {
                            Task {
                                await authManager.restoreSessionOnLaunch()
                            }
                        }
                } else if authManager.isLoggedIn {
                    // Check if we should show game recording interface
                    if case .gameRecording(let token) = appNavigator.route {
                        GameRecordingView(inviteToken: token)
                            .environmentObject(appNavigator)
                    } else if authManager.isProcessingInvite && !authManager.needsNameCollection {
                        // Show loading state while processing invite (but not for new users who need name collection)
                        ZStack {
                            Color(hex: "#9BC8EE")!.ignoresSafeArea()
                            VStack(spacing: 20) {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .tint(.white)
                                Text("Joining the party...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        MainTabView()
                            .environmentObject(partyManager)
                            .environmentObject(appNavigator)
                    }
                } else {
                    IndexView()
                }
            }
            .preferredColorScheme(.light)
            .onReceive(appNavigator.$route) { route in
                handleNavigation(route)
            }
            .alert("Error", isPresented: $appNavigator.showErrorAlert) {
                Button("OK") {
                    appNavigator.showErrorAlert = false
                }
            } message: {
                Text(appNavigator.errorMessage)
            }
            .alert(appNavigator.successTitle, isPresented: $appNavigator.showSuccessAlert) {
                Button("OK") {
                    appNavigator.showSuccessAlert = false
                }
            } message: {
                Text(appNavigator.successMessage)
            }
            .onOpenURL { url in
                // Handle Universal Links (magic links and invites)
                DeepLinkRouter.handle(url: url)
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                if let url = activity.webpageURL {
                    DeepLinkRouter.handle(url: url)
                }
            }

        }
    }
    
    private func handleNavigation(_ route: AppRoute) {
        switch route {
        case .dashboard:
            // Already on dashboard, no action needed
            break
        case .party(let partyId, let openChat):
            // For now, we'll handle party navigation through the existing system
            // The user can navigate to parties through the dashboard
            print("Navigate to party: \(partyId), openChat: \(openChat)")
        case .login:
            // Already on login, no action needed
            break
        case .signup:
            // Navigate to signup
            print("Navigate to signup")
        case .phoneAuth:
            // Navigate to phone auth
            print("Navigate to phone auth")
        case .gameRecording(let token):
            // Show game recording interface
            print("Navigate to game recording with token: \(token)")
        }
    }
}

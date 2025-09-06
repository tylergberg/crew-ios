import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var partyManager = PartyManager()
    @StateObject private var appNavigator = AppNavigator.shared
    @StateObject private var sessionManager = SessionManager()
    
    @State private var navigationPath = NavigationPath()
    @State private var showingPartyDetail = false
    @State private var targetPartyId: String?
    @State private var currentRoute: AppRoute = .dashboard
    @State private var forceUpdate = false
    
    // Navigation data for party with optional chat opening
    struct PartyNavigationData: Hashable {
        let partyId: String
        let openChat: Bool
    }

    var body: some View {
        let _ = print("🔍 RootView: Body updated, forceUpdate: \(forceUpdate), isInPhoneOnboarding: \(authManager.isInPhoneOnboarding)")
        return NavigationStack(path: $navigationPath) {
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
                    if authManager.isInPhoneOnboarding {
                        // Show phone auth view during onboarding (for name collection)
                        PhoneAuthView()
                            .onAppear {
                                print("🔍 PhoneAuthView appeared (during onboarding)")
                            }
                    } else {
                        MainTabView()
                            .environmentObject(partyManager)
                            .environmentObject(appNavigator)
                            .environmentObject(sessionManager)
                            .navigationDestination(for: PartyNavigationData.self) { data in
                                PartyDetailView(partyId: data.partyId)
                                    .environmentObject(partyManager)
                                    .environmentObject(sessionManager)
                            }
                            .onAppear {
                                print("🔍 RootView: Showing MainTabView")
                            }
                    }
                } else {
                    // Check if we should show phone auth
                    if case .phoneAuth = currentRoute {
                        PhoneAuthView()
                            .onAppear {
                                print("🔍 PhoneAuthView appeared")
                            }
                    } else {
                        IndexView()
                            .onAppear {
                                print("🔍 IndexView appeared, route: \(currentRoute)")
                            }
                    }
                }
            }
            .preferredColorScheme(.light)
            .onReceive(appNavigator.$route) { route in
                print("🔍 RootView: Route changed to: \(route)")
                currentRoute = route
                handleNavigation(route)
            }
            .onChange(of: authManager.isInPhoneOnboarding) { newValue in
                if newValue {
                    print("🔍 RootView: User needs phone onboarding")
                }
            }
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
    
    private func handleNavigation(_ route: AppRoute) {
        switch route {
        case .dashboard:
            // Reset navigation to dashboard
            navigationPath = NavigationPath()
        case .party(let partyId, let openChat):
            // Navigate to party detail with optional chat opening
            let navigationData = PartyNavigationData(partyId: partyId, openChat: openChat)
            navigationPath.append(navigationData)
        case .login:
            // Already on login, no action needed
            break
        case .signup:
            // Navigate to signup
            print("Navigate to signup")
        case .phoneAuth:
            // Already on phone auth, no action needed
            print("Navigate to phone auth")
        case .gameRecording(let token):
            // Show game recording interface
            print("Navigate to game recording with token: \(token)")
        }
    }
}


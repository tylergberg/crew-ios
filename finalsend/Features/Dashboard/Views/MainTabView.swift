import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: PartyTab = .upcoming
    @State private var showingCreateParty = false
    @State private var showingProfile = false
    @State private var shouldShowUI = false
    @State private var partiesLoaded = false
    @State private var hasCheckedForInProgressOnLaunch = false
    @State private var partyCounts: [PartyTab: Int] = [
        .upcoming: 0,
        .pending: 0,
        .declined: 0,
        .inprogress: 0,
        .attended: 0,
        .didntgo: 0
    ]
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var appNavigator: AppNavigator
    @State private var currentUserId: String? = nil
    @State private var unreadTaskCount: Int = 0
    @StateObject private var authManager = AuthManager.shared

    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neutralBackground.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Navigation Header
                    if shouldShowUI {
                        topNavigationHeader
                    }
                    
                    // Main Content
                    PartiesTabView(selectedTab: $selectedTab)
                        .environmentObject(partyManager)
                        .environmentObject(appNavigator)
                        .opacity((shouldShowUI && partiesLoaded) ? 1 : 0)
                }
                
                if !shouldShowUI || !partiesLoaded {
                    // Show loading overlay while determining the correct tab and loading parties
                    CustomLoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.neutralBackground)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: shouldShowUI)
                        .animation(.easeInOut(duration: 0.3), value: partiesLoaded)
                }
                
                // Hidden NavigationLink for profile
                NavigationLink(
                    destination: currentUserId.map { userId in
                        UnifiedProfileView(
                            userId: userId,
                            partyContext: nil,
                            isOwnProfile: true,
                            crewService: nil,
                            onCrewDataUpdated: nil,
                            showTaskManagement: true,
                            useNavigationForTasks: true
                        )
                    },
                    isActive: $showingProfile,
                    label: { EmptyView() }
                )
                .hidden()
            }
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showingCreateParty) {
            CreatePartyWizardView()
                .environmentObject(partyManager)
                .environmentObject(appNavigator)
                .navigationBarHidden(true)
        }

        .fullScreenCover(isPresented: $authManager.needsNameCollection) {
            NameCollectionView(
                phoneNumber: authManager.pendingPhoneNumber,
                fromInvite: false,
                invitePartyId: nil,
                invitePartyName: nil
            )
        }
        .onAppear {
            print("🔍 MainTabView: onAppear called")
            Task {
                // Skip profile loading if user needs name collection (new user)
                if !authManager.needsNameCollection {
                    await ProfileStore.shared.loadCurrentUserProfile()
                    currentUserId = ProfileStore.shared.current?.id
                    // Show UI for existing users
                    shouldShowUI = true
                } else {
                    print("🔍 Skipping profile load - user needs name collection")
                    // Show UI immediately for new users so they can see the name collection screen
                    shouldShowUI = true
                }
                await loadUnreadTaskCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshTaskCount)) { _ in
            // Refresh task count when notification is received
            Task {
                await loadUnreadTaskCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("partiesLoaded"))) { _ in
            print("🔍 MainTabView: Received partiesLoaded notification")
            // Mark parties as loaded and show UI
            partiesLoaded = true
            // Check for in-progress parties when parties are loaded
            checkForInProgressParties()
            // Also calculate party counts immediately
            calculatePartyCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("partyCountsUpdated"))) { notification in
            if let counts = notification.userInfo?["counts"] as? [PartyTab: Int] {
                partyCounts = counts
                print("🔍 MainTabView: Updated party counts - \(counts)")
            }
        }
        .onChange(of: selectedTab) { _ in
            // Request party counts update when tab changes
            print("🔍 MainTabView: Tab changed to \(selectedTab), requesting party counts update")
            NotificationCenter.default.post(name: Notification.Name("requestPartyCountsUpdate"), object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dismissPartyDetail"))) { _ in
            // When returning from a party, show UI immediately and mark parties as loaded
            shouldShowUI = true
            partiesLoaded = true
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("nameCollectionCompleted"))) { _ in
            // When name collection is completed, show UI and load profile
            print("🔍 MainTabView: Name collection completed, showing UI")
            shouldShowUI = true
            Task {
                await ProfileStore.shared.loadCurrentUserProfile()
                currentUserId = ProfileStore.shared.current?.id
            }
        }
    }
    
    private var topNavigationHeader: some View {
        HStack {
            // Left: Filter Button
            Menu {
                ForEach(availableTabs, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack {
                            Text("\(tab.rawValue) (\(partyCounts[tab] ?? 0))")
                            if selectedTab == tab {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(Color(hex: "#353E3E"))
            }
            
            Spacer()
            
            // Center: Crew Logo
            Image("crew-wordmark")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
            
            Spacer()
            
            // Right: Profile Button only
            Button(action: {
                showingProfile = true
            }) {
                ZStack {
                    if let userId = currentUserId {
                        // Show profile image if available
                        AsyncImage(url: URL(string: ProfileStore.shared.current?.avatar_url ?? "")) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(Color(hex: "#353E3E"))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#353E3E"), lineWidth: 2)
                        )
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(Color(hex: "#353E3E"))
                    }
                    
                    // Notification badge
                    if unreadTaskCount > 0 {
                        Text("\(unreadTaskCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color(hex: "#353E3E"))
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.2)),
            alignment: .bottom
        )
    }
    
    private var availableTabs: [PartyTab] {
        return [.upcoming, .pending, .declined, .inprogress, .attended, .didntgo]
    }
    
    private func loadUnreadTaskCount() async {
        do {
            let service = NotificationCenterService()
            unreadTaskCount = try await service.getUnreadTaskCount()
        } catch {
            print("❌ Failed to load unread task count: \(error)")
            unreadTaskCount = 0
        }
    }
    
    private func checkForInProgressParties() {
        print("🔍 MainTabView: checkForInProgressParties called")
        // This will be called when parties are loaded
        // For now, we'll just show the UI and let PartiesTabView handle the tab switching
        shouldShowUI = true
        print("🔍 MainTabView: shouldShowUI set to true")
    }
    
    private func calculatePartyCounts() {
        print("🔍 MainTabView: calculatePartyCounts called")
        // Don't override the counts - let them come from PartiesTabView via notification
        // This function is called when parties are loaded, but the actual counts
        // should be sent by PartiesTabView, not calculated here
        print("🔍 MainTabView: Waiting for party counts from PartiesTabView")
    }
}



#Preview {
    MainTabView()
        .environmentObject(PartyManager())
        .environmentObject(AppNavigator.shared)
}

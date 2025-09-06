import SwiftUI

struct MainTabView: View {
    @State private var selectedTab: PartyTab = .upcoming
    @State private var showingCreateParty = false
    @State private var showingProfile = false
    @State private var shouldShowUI = false
    @State private var partiesLoaded = false
    @State private var partyCounts: [PartyTab: Int] = [
        .upcoming: 0,
        .past: 0,
        .declined: 0
    ]
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var appNavigator: AppNavigator
    @State private var currentUserId: String? = nil
    @State private var unreadTaskCount: Int = 0
    @StateObject private var authManager = AuthManager.shared
    
    // Pre-calculated menu items to avoid computation on first touch
    @State private var cachedMenuItems: [PartyTab: String] = [:]
    
    // Loading timeout to ensure UI shows even if something goes wrong
    @State private var loadingTimeout: Timer?

    
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
                        .opacity((shouldShowUI && partiesLoaded && !authManager.isProcessingInvite) ? 1 : 0)
                }
                
                if !shouldShowUI || !partiesLoaded || authManager.isProcessingInvite {
                    // Show loading screen with sparkle icon while processing data or invite
                    SparkleLoadingView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.neutralBackground)
                        .transition(.opacity.combined(with: .scale))
                        .animation(.easeInOut(duration: 0.3), value: shouldShowUI)
                        .animation(.easeInOut(duration: 0.3), value: partiesLoaded)
                        .animation(.easeInOut(duration: 0.3), value: authManager.isProcessingInvite)
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
                fromInvite: authManager.pendingPartyId != nil,
                invitePartyId: authManager.pendingPartyId,
                invitePartyName: nil // We don't store party name in AuthManager, but that's okay
            )
        }
        .onAppear {
            print("🔍 MainTabView: onAppear called")
            // Pre-calculate menu items immediately (without counts initially)
            updateCachedMenuItems()
            
            // Set a timeout to show UI after 2 seconds even if loading isn't complete
            loadingTimeout = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
                DispatchQueue.main.async {
                    if !self.shouldShowUI && !authManager.isInPhoneOnboarding {
                        print("🔍 MainTabView: Loading timeout reached, showing UI")
                        self.shouldShowUI = true
                        self.partiesLoaded = true
                    } else if authManager.isInPhoneOnboarding {
                        print("🔍 MainTabView: Loading timeout reached but user is in phone onboarding - not showing UI")
                    }
                }
            }
            
            Task {
                // Skip profile loading if user needs name collection (new user)
                if !authManager.needsNameCollection {
                    await ProfileStore.shared.loadCurrentUserProfile()
                    currentUserId = ProfileStore.shared.current?.id
                    // Don't show UI immediately - wait for parties to load
                } else {
                    print("🔍 Skipping profile load - user needs name collection")
                    // Show UI immediately for new users so they can see the name collection screen
                    shouldShowUI = true
                }
                await loadUnreadTaskCount()
            }
        }
        .onDisappear {
            loadingTimeout?.invalidate()
            loadingTimeout = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshTaskCount)) { _ in
            // Refresh task count when notification is received
            Task {
                await loadUnreadTaskCount()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("partiesLoaded"))) { _ in
            print("🔍 MainTabView: Received partiesLoaded notification")
            // Mark parties as loaded and show UI immediately - counts are not required
            DispatchQueue.main.async {
                self.partiesLoaded = true
                self.shouldShowUI = true
                print("🔍 MainTabView: partiesLoaded set to true, shouldShowUI set to true (counts not required)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("partyCountsUpdated"))) { notification in
            if let counts = notification.userInfo?["counts"] as? [PartyTab: Int] {
                DispatchQueue.main.async {
                    self.partyCounts = counts
                    print("🔍 MainTabView: Updated party counts - \(counts)")
                    // Pre-calculate menu items to avoid computation on first touch
                    self.updateCachedMenuItems()
                }
            }
        }
        .onChange(of: selectedTab) { _ in
            // Request party counts update when tab changes
            print("🔍 MainTabView: Tab changed to \(selectedTab), requesting party counts update")
            NotificationCenter.default.post(name: Notification.Name("requestPartyCountsUpdate"), object: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dismissPartyDetail"))) { _ in
            // When returning from a party, show UI immediately and mark parties as loaded
            DispatchQueue.main.async {
                self.shouldShowUI = true
                self.partiesLoaded = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("nameCollectionCompleted"))) { _ in
            // When name collection is completed, show UI and load profile
            print("🔍 MainTabView: Name collection completed, showing UI")
            shouldShowUI = true
            partiesLoaded = true // Mark parties as loaded since user can now see the dashboard
            Task {
                await ProfileStore.shared.loadCurrentUserProfile()
                currentUserId = ProfileStore.shared.current?.id
            }
        }
    }
    
    private var topNavigationHeader: some View {
        HStack {
            // Left: Profile Button
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
            
            Spacer()
            
            // Center: Crew Logo
            Image("crew-wordmark")
                .resizable()
                .scaledToFit()
                .frame(height: 24)
            
            Spacer()
            
            // Right: Filter Button
            Menu {
                ForEach(availableTabs, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        HStack {
                            Text(cachedMenuItems[tab] ?? "\(tab.rawValue)")
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
        return [.upcoming, .past, .declined]
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
    
    
    private func updateCachedMenuItems() {
        // Pre-calculate menu item labels to avoid computation on first touch
        for tab in availableTabs {
            if let count = partyCounts[tab] {
                cachedMenuItems[tab] = "\(tab.rawValue) (\(count))"
            } else {
                // Show tab name without count if counts aren't loaded yet
                cachedMenuItems[tab] = "\(tab.rawValue)"
            }
        }
    }
}



#Preview {
    MainTabView()
        .environmentObject(PartyManager())
        .environmentObject(AppNavigator.shared)
}

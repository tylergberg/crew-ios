import SwiftUI
import Supabase

struct PartiesTabView: View {
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject private var appNavigator: AppNavigator
    @Binding var selectedTab: PartyTab
    @State private var parties: [Party] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingCreateParty = false
    @State private var currentUserId: String? = nil
    @State private var deeplinkPartyId: String? = nil
    @State private var deeplinkOpenChat: Bool = false
    @State private var scrollToTop = false
    @State private var partyCounts: [PartyTab: Int] = [
        .upcoming: 0,
        .past: 0,
        .declined: 0
    ]
    
    var body: some View {
        ZStack {
            Color.neutralBackground.ignoresSafeArea()
            VStack(spacing: 0) {
                // Party List
                partyListSection
            }
        }
        .fullScreenCover(isPresented: $showingCreateParty) {
            CreatePartyWizardView()
                .environmentObject(partyManager)
                .environmentObject(appNavigator)
                .navigationBarHidden(true)
                .onDisappear {
                    // Only fetch parties if a party was actually created
                    if partyManager.partyCreatedSuccessfully {
                        fetchParties()
                    }
                }
        }
        .fullScreenCover(isPresented: .constant(deeplinkPartyId != nil && partyManager.isLoaded), onDismiss: {
            deeplinkPartyId = nil
            deeplinkOpenChat = false
        }) {
            if let id = deeplinkPartyId {
                PartyDetailView(partyId: id)
                    .environmentObject(partyManager)
                    .environmentObject(SessionManager())
            }
        }
        .onAppear {
            print("🔍 PartiesTabView: onAppear called")
            fetchParties()
            Task {
                await ProfileStore.shared.loadCurrentUserProfile()
                currentUserId = ProfileStore.shared.current?.id
            }
        }
        .onReceive(appNavigator.$route) { route in
            switch route {
            case .party(let id, let openChat):
                // Security check: Only proceed if the party is in the user's authorized parties list
                if let party = parties.first(where: { $0.id.uuidString == id }) {
                    // Additional security check: Verify user is actually a member of this party
                    let currentUserRole = party.attendees?.first(where: { $0.isCurrentUser })?.role.rawValue
                    
                    if currentUserRole != nil {
                        print("✅ PartiesTabView: User authorized for party \(id), loading into PartyManager")
                        print("✅ PartiesTabView: Party themeId: \(party.themeId ?? "nil")")
                        print("✅ PartiesTabView: Current user role: \(currentUserRole ?? "nil")")
                        
                        deeplinkPartyId = id
                        deeplinkOpenChat = openChat
                        
                        // Clear PartyManager before loading new party data
                        partyManager.clear()
                        partyManager.load(from: PartyModel(fromParty: party), role: currentUserRole)
                        print("✅ PartiesTabView: PartyManager loaded - name: \(partyManager.name), isLoaded: \(partyManager.isLoaded), themeId: \(partyManager.themeId), role: \(partyManager.role ?? "nil")")
                    } else {
                        print("❌ PartiesTabView: User not authorized for party \(id)")
                    }
                } else {
                    // Party not found in parties list - this could be a newly created party
                    // Check if PartyManager already has the party data loaded (from creation)
                    if partyManager.partyId == id && partyManager.isLoaded {
                        print("✅ PartiesTabView: Party \(id) not in parties list but PartyManager has it loaded (newly created), proceeding with navigation")
                        deeplinkPartyId = id
                        deeplinkOpenChat = openChat
                    } else {
                        print("❌ PartiesTabView: SECURITY ALERT - User not authorized for party \(id)")
                        print("❌ PartiesTabView: Available parties: \(parties.map { $0.id.uuidString })")
                        // Navigate back to dashboard for security
                        appNavigator.navigateToDashboard()
                    }
                }
            case .dashboard:
                // Dismiss the party detail view by setting deeplinkPartyId to nil
                deeplinkPartyId = nil
                deeplinkOpenChat = false
            case .login, .signup, .phoneAuth, .gameRecording:
                break
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshPartyData)) { _ in
            // Refresh parties when notified (e.g., after party deletion)
            fetchParties()
        }
        .onReceive(NotificationCenter.default.publisher(for: .forceNavigateToDashboard)) { _ in
            // Force navigation back to dashboard (e.g., after party deletion)
            print("🔄 PartiesTabView received force navigation notification")
            deeplinkPartyId = nil
            deeplinkOpenChat = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dismissPartyDetail"))) { _ in
            // Dismiss party detail view when back button is tapped
            print("🔄 PartiesTabView received dismiss party detail notification")
            deeplinkPartyId = nil
            deeplinkOpenChat = false
            
            // Clear caches before refreshing - do this asynchronously
            DispatchQueue.main.async {
                cachedFilteredParties = []
                lastSelectedTab = nil
                cachedPartyCounts = nil
            }
            
            // Refresh parties list when returning to dashboard
            fetchParties()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("requestPartyCountsUpdate"))) { _ in
            // Send party counts when requested
            print("🔍 PartiesTabView: Received requestPartyCountsUpdate notification")
            DispatchQueue.main.async {
                self.sendPartyCounts()
            }
        }
        .onChange(of: selectedTab) { _ in
            // Reset scroll position when tab changes
            scrollToTop = true
            // Clear cache when tab changes to force recalculation - do this asynchronously
            DispatchQueue.main.async {
                cachedFilteredParties = []
                lastSelectedTab = nil
            }
        }
    }
    
    private var availableTabs: [PartyTab] {
        return [.upcoming, .past, .declined]
    }
    

    
    private var partyListSection: some View {
        ZStack {
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Top anchor for scrolling
                        Color.clear
                            .frame(height: 1)
                            .id("top")
                        
                        Spacer().frame(height: Spacing.tabsToCards)
                        
                        if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                                .padding()
                        } else if isLoading {
                            // Show loading state
                            ProgressView("Loading parties...")
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            LazyVStack(spacing: Spacing.cardGap) {
                                // Show real party cards
                                ForEach(filteredParties, id: \.id) { party in
                                    Button(action: {
                                        // Use AppNavigator for consistent navigation
                                        appNavigator.navigateToParty(party.id.uuidString, openChat: false)
                                    }) {
                                        PartyCardView(party: party)
                                            .padding(.horizontal, 24)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Always show empty card at bottom for upcoming tab
                                if selectedTab == .upcoming {
                                    Button(action: {
                                        showingCreateParty = true
                                    }) {
                                        EmptyPartyCardView {
                                            showingCreateParty = true
                                        }
                                        .padding(.horizontal, 24)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                    .padding(.bottom)
                }
                .refreshable {
                    await refreshParties()
                }
                .onChange(of: scrollToTop) { shouldScroll in
                    if shouldScroll {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            proxy.scrollTo("top", anchor: .top)
                        }
                        scrollToTop = false
                    }
                }
            }
        }
    }
    
    func fetchParties() {
        print("🔍 PartiesTabView: fetchParties called")
        isLoading = true
        errorMessage = nil
        
        Task {
            await self.fetchPartiesAsync()
        }
    }
    
    private func fetchPartiesAsync() async {
        do {
                let client = SupabaseManager.shared.client
                
                // Get current user
                let user = try await client.auth.session.user
                
                // Step 1: Get party_ids from party_member_profiles view
                struct PartyMemberProfile: Decodable {
                    let party_id: UUID
                }
                let memberships: [PartyMemberProfile] = try await client
                    .from("party_member_profiles")
                    .select("party_id")
                    .eq("user_id", value: user.id.uuidString)
                    .execute()
                    .value

                let partyIds = memberships.map { $0.party_id }

                guard !partyIds.isEmpty else {
                    await MainActor.run {
                        self.parties = []
                        self.isLoading = false
                    }
                    return
                }

                // Step 2: Fetch party info for those IDs with city data
                let fetchedParties: [Party] = try await client
                    .from("parties")
                    .select("id, name, description, start_date, end_date, cover_image_url, theme_id, party_type, party_vibe_tags, cities(id, city, state_or_province, country, timezone)")
                    .in("id", values: partyIds.map { $0.uuidString })
                    .execute()
                    .value

                // Step 3: Fetch attendee counts and current user status for dashboard efficiency
                print("🔍 [fetchParties] Fetching attendee counts for \(partyIds.count) parties")
                
                // Get attendee counts per party
                struct AttendeeCount: Decodable {
                    let party_id: UUID
                    let attendee_count: Int
                    let current_user_status: String?
                    let current_user_role: String?
                }
                
                // Try optimized RPC call first, fallback to basic query if it fails
                let attendeeCounts: [AttendeeCount]
                do {
                    struct RPCParams: Encodable {
                        let party_ids: [String]
                        let current_user_id: String
                    }
                    
                    let params = RPCParams(
                        party_ids: partyIds.map { $0.uuidString },
                        current_user_id: user.id.uuidString
                    )
                    
                    attendeeCounts = try await client
                        .rpc("get_party_attendee_counts", params: params)
                        .execute()
                        .value
                    print("🔍 [fetchParties] Fetched attendee counts for \(attendeeCounts.count) parties (optimized)")
                } catch {
                    print("⚠️ [fetchParties] RPC call failed, using fallback: \(error)")
                    // Fallback: create empty counts (dashboard will still work, just without attendee counts)
                    attendeeCounts = partyIds.map { partyId in
                        AttendeeCount(party_id: partyId, attendee_count: 0, current_user_status: nil, current_user_role: nil)
                    }
                    print("🔍 [fetchParties] Using fallback - created empty counts for \(attendeeCounts.count) parties")
                }
                
                // Create attendee count lookup
                var attendeeCountsByPartyId: [UUID: (count: Int, currentUserStatus: String?, currentUserRole: String?)] = [:]
                for countData in attendeeCounts {
                    attendeeCountsByPartyId[countData.party_id] = (
                        count: countData.attendee_count,
                        currentUserStatus: countData.current_user_status,
                        currentUserRole: countData.current_user_role
                    )
                }
                
                // Create parties with attendee counts and current user status (dashboard optimization)
                var partiesWithAttendees: [Party] = []
                for party in fetchedParties {
                    let countData = attendeeCountsByPartyId[party.id]
                    let attendeeCount = countData?.count ?? 0
                    let currentUserStatus = countData?.currentUserStatus
                    let currentUserRole = countData?.currentUserRole
                    
                    // Create a minimal attendee entry for the current user to enable proper filtering
                    var attendees: [DashboardAttendee] = []
                    if let status = currentUserStatus {
                        let currentUserAttendee = DashboardAttendee(
                            id: UUID(), // Temporary ID for dashboard
                            userId: user.id.uuidString,
                            fullName: "Current User", // Placeholder - not shown in UI
                            avatarUrl: nil,
                            role: currentUserRole ?? "attendee", // Use actual role from RPC, fallback to attendee
                            specialRole: nil,
                            status: status,
                            isCurrentUser: true
                        )
                        attendees.append(currentUserAttendee)
                    }
                    
                    let partyWithAttendees = Party(
                        id: party.id,
                        name: party.name,
                        description: party.description,
                        startDate: party.startDate,
                        endDate: party.endDate,
                        city: party.city,
                        coverImageURL: party.coverImageURL,
                        attendees: attendees, // Include current user for filtering
                        themeId: party.themeId,
                        partyType: party.partyType,
                        vibeTags: party.vibeTags,
                        attendeeCount: attendeeCount // Add the actual count from database
                    )
                    partiesWithAttendees.append(partyWithAttendees)
                }

                await MainActor.run {
                    print("🔍 PartiesTabView: Parties loaded successfully (optimized - attendee counts only)")
                    self.parties = partiesWithAttendees
                    self.isLoading = false
                    
                    // Clear caches when parties are updated
                    self.cachedFilteredParties = []
                    self.lastSelectedTab = nil
                    self.cachedPartyCounts = nil
                    
                    // Perform security check for pending navigation if parties were empty before
                    if let pendingPartyId = self.deeplinkPartyId {
                        print("🔍 PartiesTabView: Performing delayed security check for party \(pendingPartyId)")
                        if let party = self.parties.first(where: { $0.id.uuidString == pendingPartyId }) {
                            let currentUserRole = party.attendees?.first(where: { $0.isCurrentUser })?.role.rawValue
                            
                            if currentUserRole != nil {
                                print("✅ PartiesTabView: Delayed security check passed for party \(pendingPartyId)")
                                print("✅ PartiesTabView: Party themeId: \(party.themeId ?? "nil")")
                                print("✅ PartiesTabView: Current user role: \(currentUserRole ?? "nil")")
                                
                                // Clear PartyManager before loading new party data
                                self.partyManager.clear()
                                self.partyManager.load(from: PartyModel(fromParty: party), role: currentUserRole)
                                print("✅ PartiesTabView: PartyManager loaded - name: \(self.partyManager.name), isLoaded: \(self.partyManager.isLoaded), themeId: \(self.partyManager.themeId), role: \(self.partyManager.role ?? "nil")")
                            } else {
                                print("❌ PartiesTabView: Delayed security check failed - User not authorized for party \(pendingPartyId)")
                                self.deeplinkPartyId = nil
                                self.deeplinkOpenChat = false
                                self.appNavigator.navigateToDashboard()
                            }
                        } else {
                            print("❌ PartiesTabView: Delayed security check failed - Party \(pendingPartyId) not found in authorized parties")
                            self.deeplinkPartyId = nil
                            self.deeplinkOpenChat = false
                            self.appNavigator.navigateToDashboard()
                        }
                    }
                }
                
                // Calculate and send party counts after state update (asynchronously)
                DispatchQueue.main.async {
                    self.sendPartyCounts()
                }
                
                // Notify MainTabView that parties are loaded (minimal delay to ensure state is settled)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    print("🔍 PartiesTabView: Sending partiesLoaded notification")
                    NotificationCenter.default.post(name: Notification.Name("partiesLoaded"), object: nil)
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
    }
    
    func refreshParties() async {
        await withCheckedContinuation { continuation in
            fetchParties()
            // Add a small delay to ensure the fetch completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                continuation.resume()
            }
        }
    }
    
    // Cache the date formatter to avoid recreating it on every call
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    @State private var cachedFilteredParties: [Party] = []
    @State private var lastSelectedTab: PartyTab? = nil
    
    private var filteredParties: [Party] {
        // Return cached result if tab hasn't changed and we have cached data
        if selectedTab == lastSelectedTab && !cachedFilteredParties.isEmpty {
            return cachedFilteredParties
        }
        
        // If parties are empty, return empty array immediately
        guard !parties.isEmpty else {
            return []
        }
        
        let now = Date()
        
        let filtered = parties.filter { party in
            // Find current user's status
            let currentUserStatus = party.attendees?.first { $0.isCurrentUser }?.status
            let isDeclined = currentUserStatus == "declined"
            
            // If declined, always show in declined tab
            if isDeclined {
                return selectedTab == .declined
            }
            
            // Parse dates
            let _ = party.startDate.flatMap { Self.dateFormatter.date(from: $0) } // start date not used for filtering
            let end = party.endDate.flatMap { Self.dateFormatter.date(from: $0) }
            
            // Handle parties without dates - treat as upcoming
            guard let end = end else {
                return selectedTab == .upcoming
            }
            
            let isPast = end < now
            
            switch selectedTab {
            case .upcoming:
                return !isPast
            case .past:
                return isPast
            case .declined:
                return false // Already handled above
            case .pending, .inprogress, .attended, .didntgo:
                return false // These tabs are not used in this view
            }
        }
        
        let sorted = filtered.sorted { lhs, rhs in
            let lhsStart = lhs.startDate.flatMap { Self.dateFormatter.date(from: $0) }
            let rhsStart = rhs.startDate.flatMap { Self.dateFormatter.date(from: $0) }
            let lhsEnd = lhs.endDate.flatMap { Self.dateFormatter.date(from: $0) }
            let rhsEnd = rhs.endDate.flatMap { Self.dateFormatter.date(from: $0) }

            switch selectedTab {
            case .upcoming:
                // Sort by start date (parties without dates go to end)
                if lhsStart == nil && rhsStart != nil {
                    return false
                } else if lhsStart != nil && rhsStart == nil {
                    return true
                } else if lhsStart == nil && rhsStart == nil {
                    return lhs.name < rhs.name
                } else {
                    return (lhsStart ?? .distantFuture) < (rhsStart ?? .distantFuture)
                }
            case .past:
                // Sort by end date (most recent first)
                return (lhsEnd ?? .distantPast) > (rhsEnd ?? .distantPast)
            case .declined:
                // Sort declined parties: future parties first (closest to today), then past parties (most recent first)
                let lhsEnd = lhs.endDate.flatMap { Self.dateFormatter.date(from: $0) }
                let rhsEnd = rhs.endDate.flatMap { Self.dateFormatter.date(from: $0) }
                let now = Date()
                
                let lhsIsFuture = (lhsEnd ?? .distantFuture) > now
                let rhsIsFuture = (rhsEnd ?? .distantFuture) > now
                
                // If one is future and one is past, future comes first
                if lhsIsFuture && !rhsIsFuture {
                    return true
                } else if !lhsIsFuture && rhsIsFuture {
                    return false
                } else if lhsIsFuture && rhsIsFuture {
                    // Both future: sort by start date (closest to today first)
                    return (lhsStart ?? .distantFuture) < (rhsStart ?? .distantFuture)
                } else {
                    // Both past: sort by end date (most recent first)
                    return (lhsEnd ?? .distantPast) > (rhsEnd ?? .distantPast)
                }
            case .pending, .inprogress, .attended, .didntgo:
                // These tabs are not used in this view, default sorting
                return lhs.name < rhs.name
            }
        }
        
        // Update cache asynchronously after returning the result
        DispatchQueue.main.async {
            self.cachedFilteredParties = sorted
            self.lastSelectedTab = self.selectedTab
        }
        
        return sorted
    }
    
    
    @State private var cachedPartyCounts: [PartyTab: Int]? = nil
    
    private func sendPartyCounts() {
        // Return cached counts if available and parties haven't changed
        if let cached = cachedPartyCounts, !parties.isEmpty {
            DispatchQueue.main.async {
                self.partyCounts = cached
                NotificationCenter.default.post(
                    name: Notification.Name("partyCountsUpdated"),
                    object: nil,
                    userInfo: ["counts": cached]
                )
            }
            return
        }
        
        let now = Date()
        
        var counts: [PartyTab: Int] = [
            .upcoming: 0,
            .past: 0,
            .declined: 0
        ]
        
        for party in parties {
            // Find current user's status
            let currentUserStatus = party.attendees?.first { $0.isCurrentUser }?.status
            let isDeclined = currentUserStatus == "declined"
            
            // If declined, count in declined tab
            if isDeclined {
                counts[.declined]? += 1
                continue
            }
            
            // Parse end date to determine if past
            let end = party.endDate.flatMap { Self.dateFormatter.date(from: $0) }
            
            // Handle parties without dates - treat as upcoming
            guard let end = end else {
                counts[.upcoming]? += 1
                continue
            }
            
            let isPast = end < now
            
            if isPast {
                counts[.past]? += 1
            } else {
                counts[.upcoming]? += 1
            }
        }
        
        // Cache the counts and update state asynchronously
        cachedPartyCounts = counts
        
        DispatchQueue.main.async {
            self.partyCounts = counts
            
            // Send the counts to MainTabView
            NotificationCenter.default.post(
                name: Notification.Name("partyCountsUpdated"),
                object: nil,
                userInfo: ["counts": counts]
            )
        }
    }

}

#Preview {
    PartiesTabView(selectedTab: .constant(.upcoming))
        .environmentObject(PartyManager())
        .environmentObject(AppNavigator.shared)
}

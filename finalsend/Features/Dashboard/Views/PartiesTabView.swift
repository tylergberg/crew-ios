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
        .pending: 0,
        .declined: 0,
        .inprogress: 0,
        .attended: 0,
        .didntgo: 0
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
                deeplinkPartyId = id
                deeplinkOpenChat = openChat
                // Load party data into PartyManager immediately when navigation is triggered
                if let party = parties.first(where: { $0.id.uuidString == id }) {
                    print("✅ PartiesTabView: Loading party data for \(id) into PartyManager")
                    print("✅ PartiesTabView: Party themeId: \(party.themeId ?? "nil")")
                    
                    // Find the current user's role in this party
                    let currentUserRole = party.attendees?.first(where: { $0.isCurrentUser })?.role.rawValue
                    print("✅ PartiesTabView: Current user role: \(currentUserRole ?? "nil")")
                    
                    partyManager.load(from: PartyModel(fromParty: party), role: currentUserRole)
                    print("✅ PartiesTabView: PartyManager loaded - name: \(partyManager.name), isLoaded: \(partyManager.isLoaded), themeId: \(partyManager.themeId), role: \(partyManager.role ?? "nil")")
                } else {
                    print("❌ PartiesTabView: Party not found for id: \(id)")
                    print("❌ PartiesTabView: Available parties: \(parties.map { $0.id.uuidString })")
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
            
            // Refresh parties list when returning to dashboard
            fetchParties()
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("requestPartyCountsUpdate"))) { _ in
            // Send party counts when requested
            print("🔍 PartiesTabView: Received requestPartyCountsUpdate notification")
            sendPartyCounts()
        }
        .onChange(of: selectedTab) { _ in
            // Reset scroll position when tab changes
            scrollToTop = true
        }
    }
    
    private var availableTabs: [PartyTab] {
        return [.upcoming, .pending, .declined, .inprogress, .attended, .didntgo]
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
                                ForEach(filteredParties(), id: \.id) { party in
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
                    .select("id, name, start_date, end_date, cover_image_url, theme_id, party_type, party_vibe_tags, cities(id, city, state_or_province, country, timezone)")
                    .in("id", values: partyIds.map { $0.uuidString })
                    .execute()
                    .value

                // Step 3: Fetch all attendee data for all parties in a single query
                print("🔍 [fetchParties] Fetching attendees for \(partyIds.count) parties")
                let allAttendees: [DashboardAttendeeWithPartyId] = try await client
                    .from("party_members")
                    .select("""
                        id,
                        party_id,
                        user_id,
                        role,
                        special_role,
                        status,
                        profiles!party_members_user_id_fkey(
                            full_name,
                            avatar_url
                        )
                    """)
                    .in("party_id", values: partyIds.map { $0.uuidString })
                    .execute()
                    .value
                
                print("🔍 [fetchParties] Fetched \(allAttendees.count) attendees")
                
                // Group attendees by party_id
                var attendeesByPartyId: [UUID: [DashboardAttendee]] = [:]
                for attendee in allAttendees {
                    let isCurrentUser = attendee.userId.lowercased() == user.id.uuidString.lowercased()
                                            let dashboardAttendee = DashboardAttendee(
                            id: attendee.id,
                            userId: attendee.userId,
                            fullName: attendee.fullName,
                            avatarUrl: attendee.avatarUrl,
                            role: attendee.role,
                            specialRole: attendee.specialRole,
                            status: attendee.status,
                            isCurrentUser: isCurrentUser
                        )
                    
                    if attendeesByPartyId[attendee.partyId] == nil {
                        attendeesByPartyId[attendee.partyId] = []
                    }
                    attendeesByPartyId[attendee.partyId]?.append(dashboardAttendee)
                    
                    // Debug logging for current user
                    if isCurrentUser {
                        print("🔍 [fetchParties] Current user attendee - Party: \(attendee.fullName), Status: \(attendee.status), isCurrentUser: true")
                    }
                    
                    // Debug logging for all attendees
                    print("🔍 [fetchParties] Attendee - User: \(attendee.fullName), Status: \(attendee.status), isCurrentUser: \(isCurrentUser), userId: \(attendee.userId), currentUserId: \(user.id.uuidString)")
                }
                
                // Create parties with their attendees
                var partiesWithAttendees: [Party] = []
                for party in fetchedParties {
                    let attendees = attendeesByPartyId[party.id] ?? []
                    
                    let partyWithAttendees = Party(
                        id: party.id,
                        name: party.name,
                        startDate: party.startDate,
                        endDate: party.endDate,
                        city: party.city,
                        coverImageURL: party.coverImageURL,
                        attendees: attendees,
                        themeId: party.themeId,
                        partyType: party.partyType,
                        vibeTags: party.vibeTags
                    )
                    partiesWithAttendees.append(partyWithAttendees)
                }

                await MainActor.run {
                    print("🔍 PartiesTabView: Parties loaded successfully")
                    self.parties = partiesWithAttendees
                    self.isLoading = false
                    
                    // Check for in-progress parties and set default tab
                    self.checkForInProgressParties()
                    
                    // Calculate and send party counts
                    self.sendPartyCounts()
                    
                    // Notify MainTabView that parties are loaded
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
    
    private func filteredParties() -> [Party] {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return parties.filter { party in
            let start = party.startDate.flatMap { formatter.date(from: $0) }
            let end = party.endDate.flatMap { formatter.date(from: $0) }
            // Check if current user has declined this party
            let currentUserHasDeclined = party.attendees?.contains { attendee in
                let isDeclined = attendee.isCurrentUser && attendee.status == "declined"
                if attendee.isCurrentUser {
                    print("🔍 Party '\(party.name)' - Current user status: \(attendee.status), isDeclined: \(isDeclined)")
                }
                return isDeclined
            } ?? false
            
            // Check if current user has pending status for this party
            let currentUserHasPending = party.attendees?.contains { attendee in
                let isPending = attendee.isCurrentUser && attendee.status == "pending"
                if attendee.isCurrentUser {
                    print("🔍 Party '\(party.name)' - Current user status: \(attendee.status), isPending: \(isPending)")
                }
                return isPending
            } ?? false
            
            print("🔍 Party '\(party.name)' - currentUserHasDeclined: \(currentUserHasDeclined), currentUserHasPending: \(currentUserHasPending), selectedTab: \(selectedTab)")
            
            // Handle parties without dates - show them only in Upcoming
            guard let start = start, let end = end else {
                return selectedTab == .upcoming && !(currentUserHasDeclined || currentUserHasPending)
            }

            let isFuture = start > now
            let isInProgress = start <= now && end >= now
            let isPast = end < now

            switch selectedTab {
            case .upcoming:
                return isFuture && !(currentUserHasDeclined || currentUserHasPending)
            case .pending:
                return isFuture && currentUserHasPending
            case .declined:
                return isFuture && currentUserHasDeclined
            case .inprogress:
                return isInProgress && !(currentUserHasDeclined || currentUserHasPending)
            case .attended:
                return isPast && !(currentUserHasDeclined || currentUserHasPending)
            case .didntgo:
                return isPast && (currentUserHasDeclined || currentUserHasPending)
            }
        }
        .sorted { lhs, rhs in
            let lhsStart = lhs.startDate.flatMap { formatter.date(from: $0) }
            let rhsStart = rhs.startDate.flatMap { formatter.date(from: $0) }
            let lhsEnd = lhs.endDate.flatMap { formatter.date(from: $0) }
            let rhsEnd = rhs.endDate.flatMap { formatter.date(from: $0) }

            switch selectedTab {
            case .upcoming:
                // Sort parties without dates to the end, then by start date
                if lhsStart == nil && rhsStart != nil {
                    return false
                } else if lhsStart != nil && rhsStart == nil {
                    return true
                } else if lhsStart == nil && rhsStart == nil {
                    // Both have no dates, sort by name
                    return lhs.name < rhs.name
                } else {
                    return (lhsStart ?? .distantFuture) < (rhsStart ?? .distantFuture)
                }
            case .inprogress:
                return (lhsEnd ?? .distantFuture) < (rhsEnd ?? .distantFuture)
            case .attended:
                return (lhsEnd ?? .distantPast) > (rhsEnd ?? .distantPast)
            case .didntgo:
                return (lhsEnd ?? .distantPast) > (rhsEnd ?? .distantPast)
            case .declined:
                return (lhsStart ?? .distantFuture) < (rhsStart ?? .distantFuture)
            case .pending:
                return (lhsStart ?? .distantFuture) < (rhsStart ?? .distantFuture)
            }
        }
    }
    
    @State private var hasCheckedForInProgressOnLaunch = false
    
    private func checkForInProgressParties() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        print("🔍 checkForInProgressParties: Checking \(parties.count) parties")
        print("🔍 Current date: \(now)")
        print("🔍 Has checked on launch: \(hasCheckedForInProgressOnLaunch)")
        
        // Check if there are any in-progress parties (excluding declined and pending ones)
        let hasInProgressParties = parties.contains { party in
            // Skip declined parties
            let currentUserHasDeclined = party.attendees?.contains { attendee in
                attendee.isCurrentUser && attendee.status == "declined"
            } ?? false
            
            // Skip pending parties
            let currentUserHasPending = party.attendees?.contains { attendee in
                attendee.isCurrentUser && attendee.status == "pending"
            } ?? false
            
            if currentUserHasDeclined || currentUserHasPending {
                return false
            }
            
            guard let start = party.startDate.flatMap({ formatter.date(from: $0) }),
                  let end = party.endDate.flatMap({ formatter.date(from: $0) }) else {
                print("🔍 Party '\(party.name)' has no dates")
                return false
            }
            let isInProgress = start <= now && end >= now
            print("🔍 Party '\(party.name)': start=\(start), end=\(end), inProgress=\(isInProgress)")
            return isInProgress
        }
        
        print("🔍 Has in-progress parties: \(hasInProgressParties)")
        print("🔍 Current selected tab: \(selectedTab)")
        
        // Only auto-switch to in-progress on app launch, not when returning from a party
        if hasInProgressParties && selectedTab == .upcoming && !hasCheckedForInProgressOnLaunch {
            print("🔍 Switching to in-progress tab on app launch")
            selectedTab = .inprogress
        }
        
        // Mark that we've checked for in-progress parties on launch
        hasCheckedForInProgressOnLaunch = true
    }
    
    private func sendPartyCounts() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        var counts: [PartyTab: Int] = [
            .upcoming: 0,
            .pending: 0,
            .declined: 0,
            .inprogress: 0,
            .attended: 0,
            .didntgo: 0
        ]
        
        for party in parties {
            let start = party.startDate.flatMap { formatter.date(from: $0) }
            let end = party.endDate.flatMap { formatter.date(from: $0) }
            // Check if current user has declined this party
            let currentUserHasDeclined = party.attendees?.contains { attendee in
                let isDeclined = attendee.isCurrentUser && attendee.status == "declined"
                if attendee.isCurrentUser {
                    print("🔍 [sendPartyCounts] Party '\(party.name)' - Current user status: \(attendee.status), isDeclined: \(isDeclined)")
                }
                return isDeclined
            } ?? false
            
            // Check if current user has pending status for this party
            let currentUserHasPending = party.attendees?.contains { attendee in
                let isPending = attendee.isCurrentUser && attendee.status == "pending"
                if attendee.isCurrentUser {
                    print("🔍 [sendPartyCounts] Party '\(party.name)' - Current user status: \(attendee.status), isPending: \(isPending)")
                }
                return isPending
            } ?? false
            
            print("🔍 [sendPartyCounts] Party '\(party.name)' - currentUserHasDeclined: \(currentUserHasDeclined), currentUserHasPending: \(currentUserHasPending)")
            
            if currentUserHasDeclined {
                if let end = end, end < now {
                    counts[.didntgo]? += 1
                    print("🔍 [sendPartyCounts] Declined but past, added to didn't go: \(party.name)")
                } else {
                    counts[.declined]? += 1
                    print("🔍 [sendPartyCounts] Added to declined count: \(party.name)")
                }
                continue // Skip counting in other categories
            }
            
            if currentUserHasPending {
                if let end = end, end < now {
                    counts[.didntgo]? += 1
                    print("🔍 [sendPartyCounts] Pending but past, added to didn't go: \(party.name)")
                } else {
                    counts[.pending]? += 1
                    print("🔍 [sendPartyCounts] Added to pending count: \(party.name)")
                }
                continue // Skip counting in other categories
            }
            
            guard let start = start,
                  let end = end else {
                // If no dates are set, count as upcoming
                counts[.upcoming]? += 1
                continue
            }
            
            if start > now {
                counts[.upcoming]? += 1
            } else if start <= now && end >= now {
                counts[.inprogress]? += 1
            } else {
                counts[.attended]? += 1
            }
        }
        
        // Update local party counts
        self.partyCounts = counts
        
        // Send the counts to MainTabView
        NotificationCenter.default.post(
            name: Notification.Name("partyCountsUpdated"),
            object: nil,
            userInfo: ["counts": counts]
        )
    }

}

#Preview {
    PartiesTabView(selectedTab: .constant(.upcoming))
        .environmentObject(PartyManager())
        .environmentObject(AppNavigator.shared)
}

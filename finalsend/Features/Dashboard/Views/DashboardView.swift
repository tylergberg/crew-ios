import Foundation
import SwiftUI
import Supabase

extension Notification.Name {
    static let forceNavigateToDashboard = Notification.Name("forceNavigateToDashboard")
}

enum PartyTab: String, CaseIterable {
    case upcoming = "Upcoming"
    case past = "Past"
    case pending = "Pending Invites"
    case declined = "Declined Invites"
    case inprogress = "Live Trips"
    case attended = "Attended Trips"
    case didntgo = "Didn't Go"
}

struct PartyCity: Decodable {
    let id: String?
    let city: String?
    let state_or_province: String?
    let country: String?
    let timezone: String?  // Added timezone field
    
    var displayName: String {
        if let city = city, let state = state_or_province {
            return "\(city), \(state)"
        } else if let city = city {
            return city
        }
        return "Location TBD"
    }
}

struct DashboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject private var appNavigator: AppNavigator
    @State private var parties: [Party] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: PartyTab = .upcoming
    @State private var userName: String? = nil
    @State private var showingCreateParty = false
    @State private var profileImageURL: String? = nil
    @State private var showingProfile = false
    @State private var currentUserId: String? = nil
    @State private var avatarVersionTick: Int = 0
    @State private var deeplinkPartyId: String? = nil
    @State private var deeplinkOpenChat: Bool = false
    @State private var unreadTaskCount: Int = 0
    
    var body: some View {
        buildDashboardBody()
    }

    @ViewBuilder
    private func buildDashboardBody() -> some View {
        NavigationView {
            ZStack {
                Color(hex: "#353E3E").ignoresSafeArea()
                dashboardContent()
            }
            .navigationBarHidden(true)
            .fullScreenCover(isPresented: $showingCreateParty) {
                CreatePartyWizardView()
                    .environmentObject(partyManager)
                    .environmentObject(appNavigator)
                    .navigationBarHidden(true)
                    .onDisappear {
                        // Only fetch parties if a party was actually created
                        // This prevents unnecessary reload when canceling
                        if partyManager.partyCreatedSuccessfully {
                            fetchParties()
                        }
                    }
            }
            .fullScreenCover(isPresented: .constant(deeplinkPartyId != nil), onDismiss: {
                deeplinkPartyId = nil
                deeplinkOpenChat = false
            }) {
                if let id = deeplinkPartyId {
                    PartyDetailView(partyId: id)
                        .environmentObject(partyManager)
                        .environmentObject(SessionManager())
                }
            }
            .background(
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
            )
        }
        .onAppear {
            fetchParties()
            Task { 
                await ProfileStore.shared.loadCurrentUserProfile()
                await loadUnreadTaskCount()
            }
            
            // Also check for in-progress parties after a delay to ensure data is loaded
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.setDefaultTab()
            }
        }
        .onReceive(appNavigator.$route) { route in
            switch route {
            case .party(let id, let openChat):
                deeplinkPartyId = id
                deeplinkOpenChat = openChat
                // Load party data into PartyManager immediately when navigation is triggered
                if let party = parties.first(where: { $0.id.uuidString == id }) {
                    print("✅ DashboardView: Loading party data for \(id) into PartyManager")
                    print("✅ DashboardView: Party themeId: \(party.themeId ?? "nil")")
                    
                    // Find the current user's role in this party
                    let currentUserRole = party.attendees?.first(where: { $0.isCurrentUser })?.role.rawValue
                    print("✅ DashboardView: Current user role: \(currentUserRole ?? "nil")")
                    
                    // Clear PartyManager before loading new party data
                    partyManager.clear()
                    partyManager.load(from: PartyModel(fromParty: party), role: currentUserRole)
                    print("✅ DashboardView: PartyManager loaded - name: \(partyManager.name), isLoaded: \(partyManager.isLoaded), themeId: \(partyManager.themeId), role: \(partyManager.role ?? "nil")")
                } else {
                    // Party not found in parties list - this could be a newly created party
                    // Check if PartyManager already has the party data loaded (from creation)
                    if partyManager.partyId == id && partyManager.isLoaded {
                        print("✅ DashboardView: Party \(id) not in parties list but PartyManager has it loaded (newly created), proceeding with navigation")
                    } else {
                        print("❌ DashboardView: Party not found for id: \(id)")
                        print("❌ DashboardView: Available parties: \(parties.map { $0.id.uuidString })")
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
            print("🔄 Dashboard received force navigation notification")
            deeplinkPartyId = nil
            deeplinkOpenChat = false
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("dismissPartyDetail"))) { _ in
            // Dismiss party detail view when back button is tapped
            print("🔄 Dashboard received dismiss party detail notification")
            deeplinkPartyId = nil
            deeplinkOpenChat = false
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshTaskCount)) { _ in
            // Refresh task count when notification is received
            Task {
                await loadUnreadTaskCount()
            }
        }
    }

    private func dashboardContent() -> some View {
        VStack(spacing: 0) {
            DashboardHeaderView(
                selectedTab: $selectedTab,
                profileImageURL: versionedHeaderURL,
                onNewPartyTapped: { showingCreateParty = true },
                onProfileTapped: { showingProfile = true },
                onLogoutTapped: {
                    print("Logout tapped – implement navigation and session clearing")
                },
                userName: displayName,
                unreadTaskCount: unreadTaskCount,
                isProfileIncomplete: isProfileIncomplete
            )
            .padding(.top)
            .onReceive(NotificationCenter.default.publisher(for: .avatarUpdated)) { notif in
                guard let changedId = notif.userInfo?["userId"] as? String else { return }
                guard changedId == currentUserId else { return }
                // Prefer direct URL from notification (unique path). Fallback to re-fetch.
                if let newURL = notif.userInfo?["avatar_url"] as? String {
                    profileImageURL = newURL
                } else {
                    Task { await ProfileStore.shared.loadCurrentUserProfile() }
                }
                avatarVersionTick &+= 1
            }

            CategoryTabsView(selectedTab: $selectedTab)
                .padding(.top, 8)
            
            partyListSection()
        }
    }

    private func partyListSection() -> some View {
        ZStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
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
                await refreshDashboard()
            }
        }
    }

    func fetchParties() {
        print("🔍 fetchParties: Starting to fetch parties")
        isLoading = true
        errorMessage = nil

        let client = SupabaseClient(
            supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
        )

        Task {
            do {
                // Swift 6: Always use async session getter, handle errors
                do {
                    let session = try await client.auth.session
                    let user = session.user
                    self.currentUserId = user.id.uuidString

                    // Fetch user profile
                    struct Profile: Decodable {
                        let full_name: String?
                        let avatar_url: String?
                    }

                    do {
                        let profile: Profile = try await client
                            .from("profiles")
                            .select("full_name, avatar_url")
                            .eq("id", value: user.id.uuidString)
                            .single()
                            .execute()
                            .value

                        self.userName = profile.full_name
                        self.profileImageURL = profile.avatar_url
                    } catch {
                        print("Failed to fetch user profile:", error.localizedDescription)
                    }

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
                        self.parties = []
                        self.isLoading = false
                        return
                    }

                                    // Step 2: Fetch party info for those IDs with city data
                let fetchedParties: [Party] = try await client
                    .from("parties")
                    .select("id, name, description, start_date, end_date, cover_image_url, theme_id, party_type, party_vibe_tags, cities(id, city, state_or_province, country, timezone)")
                    .in("id", values: partyIds.map { $0.uuidString })
                    .execute()
                    .value

                    // Step 3: Fetch all attendee data for all parties in a single query
                    let allAttendees: [DashboardAttendeeWithPartyId] = try await client
                        .from("party_members")
                        .select("""
                            id,
                            party_id,
                            user_id,
                            role,
                            special_role,
                            profiles!party_members_user_id_fkey(
                                full_name,
                                avatar_url
                            )
                        """)
                        .in("party_id", values: partyIds.map { $0.uuidString })
                        .execute()
                        .value
                    
                    // Group attendees by party_id
                    var attendeesByPartyId: [UUID: [DashboardAttendee]] = [:]
                    for attendee in allAttendees {
                        let dashboardAttendee = DashboardAttendee(
                            id: attendee.id,
                            userId: attendee.userId,
                            fullName: attendee.fullName,
                            avatarUrl: attendee.avatarUrl,
                            role: attendee.role,
                            specialRole: attendee.specialRole,
                            status: attendee.status,
                            isCurrentUser: attendee.userId == user.id.uuidString
                        )
                        
                        if attendeesByPartyId[attendee.partyId] == nil {
                            attendeesByPartyId[attendee.partyId] = []
                        }
                        attendeesByPartyId[attendee.partyId]?.append(dashboardAttendee)
                    }
                    
                    // Create parties with their attendees
                    var partiesWithAttendees: [Party] = []
                    for party in fetchedParties {
                        let attendees = attendeesByPartyId[party.id] ?? []
                        
                        let partyWithAttendees = Party(
                            id: party.id,
                            name: party.name,
                            description: party.description,
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

                    self.parties = partiesWithAttendees
                    
                    print("🔍 fetchParties: Loaded \(partiesWithAttendees.count) parties")
                    
                    // Set default tab to in-progress if there are live parties
                    DispatchQueue.main.async {
                        print("🔍 fetchParties: About to call setDefaultTab")
                        self.setDefaultTab()
                    }
                    
                    self.isLoading = false
                } catch {
                    print("🔍 fetchParties: Error occurred: \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        self.errorMessage = "Session error: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    private func setDefaultTab() {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        print("🔍 setDefaultTab: Checking \(parties.count) parties")
        print("🔍 Current date: \(now)")
        
        // Check if there are any in-progress parties
        let hasInProgressParties = parties.contains { party in
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
        
        // If there are in-progress parties, switch to in-progress tab
        if hasInProgressParties {
            print("🔍 Switching to in-progress tab")
            selectedTab = .inprogress
        }
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

            let currentUserHasDeclined = party.attendees?.contains { attendee in
                attendee.isCurrentUser && attendee.status == "declined"
            } ?? false
            let currentUserHasPending = party.attendees?.contains { attendee in
                attendee.isCurrentUser && attendee.status == "pending"
            } ?? false

            if currentUserHasDeclined {
                if let end = end, end < now {
                    counts[.didntgo]? += 1
                } else {
                    counts[.declined]? += 1
                }
                continue
            }
            if currentUserHasPending {
                if let end = end, end < now {
                    counts[.didntgo]? += 1
                } else {
                    counts[.pending]? += 1
                }
                continue
            }

            guard let start = start, let end = end else {
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
        
        print("🔍 sendPartyCounts: \(counts)")
        
        // Send the counts to MainTabView
        NotificationCenter.default.post(
            name: Notification.Name("partyCountsUpdated"),
            object: nil,
            userInfo: ["counts": counts]
        )
    }

    func filteredParties() -> [Party] {
        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return parties.filter { party in
            let start = party.startDate.flatMap { formatter.date(from: $0) }
            let end = party.endDate.flatMap { formatter.date(from: $0) }

            let currentUserHasDeclined = party.attendees?.contains { attendee in
                attendee.isCurrentUser && attendee.status == "declined"
            } ?? false
            let currentUserHasPending = party.attendees?.contains { attendee in
                attendee.isCurrentUser && attendee.status == "pending"
            } ?? false

            // No dates → only show in Upcoming (confirmed)
            guard let start = start, let end = end else {
                return selectedTab == .upcoming && !(currentUserHasDeclined || currentUserHasPending)
            }

            let isFuture = start > now
            let isInProgress = start <= now && end >= now
            let isPast = end < now

            switch selectedTab {
            case .upcoming:
                return isFuture && !(currentUserHasDeclined || currentUserHasPending)
            case .past:
                return isPast && !(currentUserHasDeclined || currentUserHasPending)
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
        .sorted { (lhs: Party, rhs: Party) -> Bool in
            let lhsStart = lhs.startDate.flatMap { formatter.date(from: $0) }
            let rhsStart = rhs.startDate.flatMap { formatter.date(from: $0) }
            let lhsEnd = lhs.endDate.flatMap { formatter.date(from: $0) }
            let rhsEnd = rhs.endDate.flatMap { formatter.date(from: $0) }

            switch selectedTab {
            case .upcoming, .pending, .declined:
                // Start date ascending; undated at end for Upcoming case
                return (lhsStart ?? .distantFuture) < (rhsStart ?? .distantFuture)
            case .past, .inprogress, .attended, .didntgo:
                // End date descending (most recent first)
                return (lhsEnd ?? .distantPast) > (rhsEnd ?? .distantPast)
            }
        }
    }

    func daysAwayString(for party: Party) -> String {
        let formatter = ISO8601DateFormatter()
        guard let start = party.startDate.flatMap({ formatter.date(from: $0) }) else { return "" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: start).day ?? 0
        return "\(days) days away"
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
    
    private func refreshDashboard() async {
        // Refresh parties data
        fetchParties()
        
        // Refresh user profile and task count
        await ProfileStore.shared.loadCurrentUserProfile()
        await loadUnreadTaskCount()
    }
    
    // MARK: - Computed Properties
    private var versionedHeaderURL: URL? {
        // Prefer store's current if available
        let base = ProfileStore.shared.current?.avatar_url ?? profileImageURL
        guard let baseURL = base, !baseURL.isEmpty else { return nil }
        
        // Add avatarVersionTick to force refresh when avatar is updated
        let refreshURL = baseURL + (baseURL.contains("?") ? "&" : "?") + "refresh=\(avatarVersionTick)"
        return URL(string: refreshURL)
    }

    private var displayName: String {
        userName ?? "Guest"
    }
    
    private var isProfileIncomplete: Bool {
        guard let profile = ProfileStore.shared.current else { return true }
        
        // Check if essential profile fields are missing
        let hasName = profile.full_name != nil && !profile.full_name!.isEmpty
        let hasPhone = profile.phone != nil && !profile.phone!.isEmpty
        let hasAddress = profile.home_address != nil && !profile.home_address!.isEmpty
        let hasBirthday = profile.birthday != nil && !profile.birthday!.isEmpty
        let hasFunFact = profile.fun_stat != nil && !profile.fun_stat!.isEmpty
        
        // Profile is incomplete if any of these essential fields are missing
        return !hasName || !hasPhone || !hasAddress || !hasBirthday || !hasFunFact
    }
}

struct Party: Identifiable, Decodable {
    let id: UUID
    let name: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let city: PartyCity?
    let coverImageURL: String?
    let attendees: [DashboardAttendee]?
    let themeId: String?
    let partyType: String?
    let vibeTags: [String]?
    let attendeeCount: Int? // Add attendee count from database

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case coverImageURL = "cover_image_url"
        case city = "cities"
        case themeId = "theme_id"
        case partyType = "party_type"
        case vibeTags = "party_vibe_tags"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        self.endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        self.coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        self.city = try container.decodeIfPresent(PartyCity.self, forKey: .city)
        self.themeId = try container.decodeIfPresent(String.self, forKey: .themeId)
        self.partyType = try container.decodeIfPresent(String.self, forKey: .partyType)
        self.vibeTags = try container.decodeIfPresent([String].self, forKey: .vibeTags)
        self.attendees = nil // Will be set manually after fetching
        self.attendeeCount = nil // Will be set manually after fetching
    }
    
    // Custom initializer for creating instances with attendees
    init(id: UUID, name: String, description: String? = nil, startDate: String?, endDate: String?, city: PartyCity?, coverImageURL: String?, attendees: [DashboardAttendee]?, themeId: String? = "default", partyType: String? = nil, vibeTags: [String]? = nil, attendeeCount: Int? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.startDate = startDate
        self.endDate = endDate
        self.city = city
        self.coverImageURL = coverImageURL
        self.attendees = attendees
        self.themeId = themeId
        self.partyType = partyType
        self.vibeTags = vibeTags
        self.attendeeCount = attendeeCount
    }
}

// MARK: - Dashboard Attendee Model
struct DashboardAttendee: Identifiable, Decodable {
    let id: UUID
    let userId: String
    let fullName: String
    let avatarUrl: String?
    let role: String
    let specialRole: String?
    let status: String
    let isCurrentUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case role
        case specialRole = "special_role"
        case profiles
    }
    
    struct ProfileData: Decodable {
        let fullName: String?
        let avatarUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case avatarUrl = "avatar_url"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.role = try container.decode(String.self, forKey: .role)
        self.specialRole = try container.decodeIfPresent(String.self, forKey: .specialRole)
        
        let profileData = try container.decodeIfPresent(ProfileData.self, forKey: .profiles)
        self.fullName = profileData?.fullName ?? "Unknown User"
        self.avatarUrl = profileData?.avatarUrl
        
        // These will be set by the service layer
        self.status = "pending"
        self.isCurrentUser = false
    }
    
    // Custom initializer for creating instances manually
    init(id: UUID, userId: String, fullName: String, avatarUrl: String?, role: String, specialRole: String?, status: String, isCurrentUser: Bool) {
        self.id = id
        self.userId = userId
        self.fullName = fullName
        self.avatarUrl = avatarUrl
        self.role = role
        self.specialRole = specialRole
        self.status = status
        self.isCurrentUser = isCurrentUser
    }
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return fullName.prefix(2).uppercased()
        }
    }
}

// MARK: - Dashboard Attendee With Party ID (for fetching)
struct DashboardAttendeeWithPartyId: Identifiable, Decodable {
    let id: UUID
    let partyId: UUID
    let userId: String
    let fullName: String
    let avatarUrl: String?
    let role: String
    let specialRole: String?
    let status: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case role
        case specialRole = "special_role"
        case status
        case profiles
    }
    
    struct ProfileData: Decodable {
        let fullName: String?
        let avatarUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case fullName = "full_name"
            case avatarUrl = "avatar_url"
        }
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.partyId = try container.decode(UUID.self, forKey: .partyId)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.role = try container.decode(String.self, forKey: .role)
        self.specialRole = try container.decodeIfPresent(String.self, forKey: .specialRole)
        self.status = try container.decode(String.self, forKey: .status)
        
        let profileData = try container.decodeIfPresent(ProfileData.self, forKey: .profiles)
        self.fullName = profileData?.fullName ?? "Unknown User"
        self.avatarUrl = profileData?.avatarUrl
    }
}

#Preview {
    DashboardView()
}

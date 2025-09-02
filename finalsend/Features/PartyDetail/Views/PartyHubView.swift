import SwiftUI

// MARK: - Centralized Data Manager
@MainActor
class PartyDataManager: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    
    // Shared stores
    @Published var expensesStore: ExpensesStore?
    @Published var lodgingStore: LodgingStore?
    @Published var packingStore: PackingStore?
    @Published var tasksStore: TasksStore?
    @Published var vendorService: VendorService?
    @Published var itineraryService: ItineraryService?
    @Published var flightsService: FlightsService?
    @Published var gamesService: PartyGamesService?
    @Published var galleryService: GalleryService?
    @Published var galleryStore: GalleryStore?
    @Published var cityLookupService: CityLookupService?
    
    // Cached data
    @Published var vendorCount: Int = 0
    @Published var eventCount: Int = 0
    @Published var nextEvent: ItineraryEvent?
    @Published var flightCount: Int = 0
    @Published var packingCount: Int = 0
    @Published var gamesCount: Int = 0
    @Published var galleryCount: Int = 0
    @Published var currentCity: CityCore?
    
    // Shared attendee data - CACHED to prevent duplicate fetches
    @Published var attendees: [PartyAttendee] = []
    @Published var isAttendeesLoading = false
    
    private var currentPartyId: String?
    private var currentUserId: String?
    private var attendeesCount: Int = 0
    private var hasLoadedData = false
    private var hasLoadedAttendees = false
    
    // MARK: - Centralized Attendee Loading
    func loadAttendees(partyId: String, currentUserId: String) async {
        // Skip if already loaded for this party
        if hasLoadedAttendees && currentPartyId == partyId {
            AppLogger.debug("PartyDataManager: Attendees already loaded for party \(partyId), skipping reload")
            return
        }
        
        AppLogger.data("PartyDataManager: Loading attendees for party \(partyId)")
        
        self.currentPartyId = partyId
        self.currentUserId = currentUserId
        self.isAttendeesLoading = true
        
        do {
            // Use view with joined profile data to align with RLS and schema
            struct PartyMemberRow: Decodable {
                let id: UUID
                let party_id: String
                let user_id: String
                let role: String
                let status: String
                let special_role: String?
                let created_at: String?
                let updated_at: String?
                let full_name: String?
                let avatar_url: String?
                let email: String?
            }

            let response: [PartyMemberRow] = try await SupabaseManager.shared.client
                .from("party_member_view")
                .select("""
                    id,
                    party_id,
                    user_id,
                    role,
                    status,
                    special_role,
                    created_at,
                    updated_at,
                    full_name,
                    avatar_url,
                    email
                """)
                .eq("party_id", value: partyId)
                .execute()
                .value
            
            AppLogger.debug("PartyDataManager: Raw attendees response count: \(response.count)")
            
            // Convert to PartyAttendee objects
            var attendeesWithCurrentUser: [PartyAttendee] = []
            
            for member in response {
                let fullName = member.full_name ?? "Unknown"
                let email = member.email ?? ""
                let avatarUrl = member.avatar_url
                
                // Map role string to UserRole enum
                let userRole: UserRole
                switch member.role.lowercased() {
                case "admin":
                    userRole = .admin
                case "organizer":
                    userRole = .organizer
                case "attendee":
                    userRole = .attendee
                case "guest":
                    userRole = .guest
                default:
                    userRole = .guest
                }
                
                // Map status string to RsvpStatus enum
                let rsvpStatus: RsvpStatus
                switch member.status.lowercased() {
                case "confirmed":
                    rsvpStatus = .confirmed
                case "pending":
                    rsvpStatus = .pending
                case "declined":
                    rsvpStatus = .declined
                default:
                    rsvpStatus = .pending
                }
                
                let specialRole: String?
                if let specialRoleFromField = member.special_role, !specialRoleFromField.isEmpty {
                    specialRole = specialRoleFromField
                } else if member.role == "groom" || member.role == "bride" {
                    specialRole = member.role
                } else {
                    specialRole = nil
                }
                
                let attendee = PartyAttendee(
                    id: member.id,
                    userId: member.user_id,
                    partyId: member.party_id,
                    fullName: fullName,
                    email: email,
                    avatarUrl: avatarUrl,
                    role: userRole,
                    rsvpStatus: rsvpStatus,
                    specialRole: specialRole,
                    invitedAt: ISO8601DateFormatter().date(from: member.created_at ?? ""),
                    respondedAt: ISO8601DateFormatter().date(from: member.updated_at ?? ""),
                    isCurrentUser: member.user_id == currentUserId
                )
                
                attendeesWithCurrentUser.append(attendee)
            }
            
            self.attendees = attendeesWithCurrentUser.sorted { $0.fullName < $1.fullName }
            self.attendeesCount = attendeesWithCurrentUser.count
            self.hasLoadedAttendees = true
            
            AppLogger.success("PartyDataManager: Loaded \(self.attendees.count) attendees")
            
        } catch {
            AppLogger.error("PartyDataManager: Failed to fetch attendees: \(error)")
            self.errorMessage = "Failed to load attendees: \(error.localizedDescription)"
        }
        
        self.isAttendeesLoading = false
    }
    
    func loadAllData(partyId: String, currentUserId: String, attendeesCount: Int) async {
        AppLogger.data("PartyDataManager: loadAllData called for party \(partyId)")
        AppLogger.debug("PartyDataManager: hasLoadedData: \(hasLoadedData), currentPartyId: \(currentPartyId ?? "nil")")
        
        // Skip if already loaded for this party
        if hasLoadedData && currentPartyId == partyId {
            AppLogger.debug("PartyDataManager: Data already loaded for party \(partyId), skipping reload")
            return
        }
        
        AppLogger.data("PartyDataManager: Starting to load all data for party \(partyId)")
        
        self.currentPartyId = partyId
        self.currentUserId = currentUserId
        self.attendeesCount = attendeesCount
        self.isLoading = true
        self.errorMessage = nil
        self.successMessage = nil
        
        // Initialize shared services
        self.expensesStore = ExpensesStore(supabase: SupabaseManager.shared.client)
        self.lodgingStore = LodgingStore(supabase: SupabaseManager.shared.client)
        self.vendorService = VendorService()
        self.itineraryService = ItineraryService()
        self.flightsService = FlightsService(supabase: SupabaseManager.shared.client)
        self.gamesService = PartyGamesService.shared
        self.galleryService = GalleryService()
        self.galleryStore = GalleryStore(partyId: UUID(uuidString: partyId) ?? UUID(), currentUserId: UUID(uuidString: currentUserId) ?? UUID())
        self.cityLookupService = CityLookupService()
        
        // Initialize packing store
        let supabase = SupabaseManager.shared.client
        self.packingStore = PackingStore(supabase: supabase)
        
        // Initialize tasks store
        self.tasksStore = TasksStore()
        
        // Load attendees first (shared data)
        await loadAttendees(partyId: partyId, currentUserId: currentUserId)
        
        // Load all other data concurrently
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.loadExpensesData() }
            group.addTask { await self.loadLodgingData() }
            group.addTask { await self.loadVendorData() }
            group.addTask { await self.loadItineraryData() }
            group.addTask { await self.loadFlightData() }
            group.addTask { await self.loadPackingData() }
            group.addTask { await self.loadTasksData() }
            group.addTask { await self.loadGamesData() }
            group.addTask { await self.loadGalleryData() }
        }
        
        self.isLoading = false
        self.hasLoadedData = true
        AppLogger.success("PartyDataManager: All data loaded successfully")
    }
    
    private func loadExpensesData() async {
        guard let partyUUID = UUID(uuidString: currentPartyId ?? ""),
              let userUUID = UUID(uuidString: currentUserId ?? "") else { return }
        
        // Pass the already-loaded attendees to prevent duplicate fetch
        await expensesStore?.loadAllWithAttendees(
            partyId: partyUUID, 
            userId: userUUID
        )
    }
    
    private func loadLodgingData() async {
        guard let partyUUID = UUID(uuidString: currentPartyId ?? "") else { return }
        await lodgingStore?.loadLodgings(partyId: partyUUID)
    }
    
    private func loadVendorData() async {
        // Vendor data is loaded on-demand when cityId is available
        // This will be called when the city data is loaded
    }
    
    func loadVendorDataForCity(cityId: UUID) async {
        AppLogger.data("PartyDataManager: Loading vendor data for city \(cityId)")
        do {
            let vendors = try await vendorService?.fetchVendors(cityId: cityId) ?? []
            vendorCount = vendors.count
            AppLogger.success("PartyDataManager: Loaded \(vendorCount) vendors for city \(cityId)")
        } catch {
            AppLogger.error("Error loading vendors: \(error)")
            vendorCount = 0
        }
    }
    
    private func loadItineraryData() async {
        guard let partyId = currentPartyId else { return }
        
        await itineraryService?.fetchEvents(for: partyId)
        
        // Find the next upcoming event
        let now = Date()
        let upcomingEvents = itineraryService?.events.filter { event in
            guard let startDate = event.startDate else { return false }
            return startDate > now
        }.sorted { first, second in
            guard let firstDate = first.startDate, let secondDate = second.startDate else { return false }
            return firstDate < secondDate
        } ?? []
        
        eventCount = itineraryService?.events.count ?? 0
        nextEvent = upcomingEvents.first
    }
    
    private func loadFlightData() async {
        guard let partyUUID = UUID(uuidString: currentPartyId ?? "") else { return }
        
        do {
            let flights = try await flightsService?.fetchFlights(partyId: partyUUID) ?? []
            flightCount = flights.count
        } catch {
            print("❌ Error loading flights: \(error)")
            flightCount = 0
        }
    }
    
    private func loadPackingData() async {
        guard let partyUUID = UUID(uuidString: currentPartyId ?? ""),
              let userUUID = UUID(uuidString: currentUserId ?? "") else { return }
        
        await packingStore?.load(partyId: partyUUID, userId: userUUID)
        packingCount = packingStore?.items.count ?? 0
    }
    
    private func loadTasksData() async {
        guard let partyUUID = UUID(uuidString: currentPartyId ?? "") else { return }
        
        await tasksStore?.load(partyId: partyUUID)
    }
    
    private func loadGamesData() async {
        guard let partyId = currentPartyId else { return }
        
        do {
            let games = try await gamesService?.fetchGames(partyId: partyId) ?? []
            gamesCount = games.count
        } catch {
            print("❌ Error loading games: \(error)")
            gamesCount = 0
        }
    }
    
    private func loadGalleryData() async {
        guard let partyUUID = UUID(uuidString: currentPartyId ?? "") else { return }
        
        do {
            let items = try await galleryService?.fetchItems(partyId: partyUUID, page: 0, limit: 100) ?? []
            galleryCount = items.count
        } catch {
            print("❌ Error loading gallery items: \(error)")
            galleryCount = 0
        }
    }
    
    func loadCityData(cityId: UUID?) async {
        AppLogger.data("PartyDataManager: Loading city data for cityId: \(cityId?.uuidString ?? "nil")")
        guard let cityId = cityId else {
            currentCity = nil
            vendorCount = 0
            AppLogger.debug("PartyDataManager: No cityId provided, clearing city and vendor data")
            return
        }
        
        do {
            if let city = try await cityLookupService?.fetchCityById(cityId) {
                currentCity = city
                AppLogger.success("PartyDataManager: Loaded city: \(city.city)")
                // Load vendor data for this city
                await loadVendorDataForCity(cityId: cityId)
            } else {
                AppLogger.warning("PartyDataManager: City not found for cityId: \(cityId)")
            }
        } catch {
            AppLogger.error("Error loading city data: \(error)")
        }
    }
    
    func refreshData() async {
        hasLoadedData = false
        hasLoadedAttendees = false
        if let partyId = currentPartyId,
           let userId = currentUserId {
            await loadAllData(partyId: partyId, currentUserId: userId, attendeesCount: attendeesCount)
        }
    }
    
    func cleanup() {
        expensesStore?.cleanup()
        packingStore?.teardown()
        tasksStore?.teardown()
        hasLoadedData = false
        hasLoadedAttendees = false
    }
}

// MARK: - Main Party Hub View
struct PartyHubView: View {
    let partyId: String
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var sessionManager: SessionManager
    @StateObject private var dataManager = PartyDataManager()
    @State private var showChatModal = false
    @State private var showExpensesModal = false
    @State private var showTransportModal = false
    @State private var showLodgingModal = false
    @State private var showItineraryModal = false
    @State private var showTasksModal = false
    @State private var showPackingModal = false
    @State private var showGamesModal = false
    @State private var showGalleryModal = false
    @State private var showVendorsModal = false
    @State private var showShopModal = false
    @State private var showCrewModal = false

    @State private var chatAttendees: [ChatUserSummary] = []
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 24) {
                // Party header with square cover image (like dashboard)
                VStack(alignment: .leading, spacing: 16) {
                    GeometryReader { geometry in
                        ZStack(alignment: .topTrailing) {
                            CoverPhotoView(
                                imageURL: partyManager.coverImageURL,
                                width: geometry.size.width,
                                height: geometry.size.width,
                                cornerRadius: 16,
                                placeholderIcon: "photo",
                                placeholderText: "No Cover Photo"
                            )
                            
                            if let statusText = statusPillText() {
                                Text(statusText)
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(getStatusBackgroundColor())
                                    .cornerRadius(8)
                                    .padding(12)
                            }
                        }
                        .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    
                    Text(partyManager.name.isEmpty ? "Untitled Party" : partyManager.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.titleDark)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    if !partyManager.description.isEmpty {
                        Text(partyManager.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(20)
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(partyManager.currentTheme.primaryAccentColor.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                
                // Crew (summary row)
                FeaturePreviewCard(
                    title: "Crew",
                    subtitle: dataManager.isAttendeesLoading ? "Loading attendees…" : (dataManager.attendees.isEmpty ? "No attendees yet" : "\(dataManager.attendees.count) attendees"),
                    icon: "person.3.fill",
                    color: .brandBlue,
                    action: { showCrewModal = true }
                )
                
                // Party Type (summary row)
                FeaturePreviewCard(
                    title: "Party Type",
                    subtitle: partyManager.partyType.isEmpty ? "Not specified" : partyManager.partyType,
                    icon: "tag.fill",
                    color: .brandBlue,
                    action: {}
                )
                
                // Dates (summary row)
                FeaturePreviewCard(
                    title: "Dates",
                    subtitle: {
                        let f = DateFormatter()
                        f.dateStyle = .medium
                        f.timeStyle = .none
                        return "Start: \(f.string(from: partyManager.startDate)) – End: \(f.string(from: partyManager.endDate))"
                    }(),
                    icon: "calendar",
                    color: .brandBlue,
                    action: {}
                )
                
                // Feature placeholders – flat list
                FeaturePreviewCard(
                    title: "Location",
                    subtitle: "Set destination & city",
                    icon: "mappin.and.ellipse",
                    color: .brandBlue,
                    action: {}
                )
                FeaturePreviewCard(
                    title: "Vibe",
                    subtitle: "Theme, colors, energy",
                    icon: "sparkles",
                    color: .purple,
                    action: {}
                )
                FeaturePreviewCard(
                    title: "Itinerary",
                    subtitle: "Plan events & schedule",
                    icon: "calendar.badge.clock",
                    color: .indigo,
                    action: { showItineraryModal = true }
                )
                FeaturePreviewCard(
                    title: "Transport",
                    subtitle: "Flights & rides",
                    icon: "car",
                    color: .teal,
                    action: { showTransportModal = true }
                )
                FeaturePreviewCard(
                    title: "Lodging",
                    subtitle: "Stay details & rooms",
                    icon: "house",
                    color: .orange,
                    action: { showLodgingModal = true }
                )
                FeaturePreviewCard(
                    title: "Packing",
                    subtitle: "Shared packing lists",
                    icon: "shippingbox",
                    color: .orange,
                    action: { showPackingModal = true }
                )
                FeaturePreviewCard(
                    title: "Shop",
                    subtitle: "Merch & supplies",
                    icon: "tshirt",
                    color: .mint,
                    action: { showShopModal = true }
                )
                FeaturePreviewCard(
                    title: "Games",
                    subtitle: "Activities & icebreakers",
                    icon: "gamecontroller",
                    color: .pink,
                    action: { showGamesModal = true }
                )
                FeaturePreviewCard(
                    title: "Expenses",
                    subtitle: "Track spending & splits",
                    icon: "dollarsign.circle",
                    color: .green,
                    action: { showExpensesModal = true }
                )
                FeaturePreviewCard(
                    title: "Album",
                    subtitle: "Photos & memories",
                    icon: "photo.on.rectangle",
                    color: .indigo,
                    action: { showGalleryModal = true }
                )
                FeaturePreviewCard(
                    title: "AI Assistant",
                    subtitle: "Plan smarter with AI",
                    icon: "wand.and.stars",
                    color: .purple,
                    action: {}
                )
                FeaturePreviewCard(
                    title: "Chat",
                    subtitle: "Group messages",
                    icon: "message",
                    color: .brandBlue,
                    action: { showChatModal = true }
                )
                
                // RSVP Section
                if let currentUserAttendee = dataManager.attendees.first(where: { $0.isCurrentUser }) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "envelope")
                                .font(.title3)
                                .foregroundColor(.brandBlue)
                                .frame(width: 24)
                            
                            Text("RSVP")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.titleDark)
                            
                            Spacer()
                            
                            Text("Update")
                            .font(.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.brandBlue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                        }
                        
                        Text("Status: \(currentUserAttendee.rsvpStatus.rawValue.capitalized)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(partyManager.currentTheme.primaryAccentColor.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16) // Add top padding to avoid navigation bar
            
        }
        .background(partyManager.currentTheme.cardBackgroundColor)
        .refreshable {
            await refreshPartyData()
        }
        .fullScreenCover(isPresented: $showChatModal) {
            if let partyIdUUID = UUID(uuidString: partyId) {
                ChatModalView(
                    partyId: partyIdUUID,
                    partyName: partyManager.name.isEmpty ? "Untitled Party" : partyManager.name,
                    attendees: chatAttendees
                )
            }
        }
        
        // Feature modals
        .fullScreenCover(isPresented: $showExpensesModal) {
            ExpensesTabView(
                partyId: partyId,
                currentUserId: sessionManager.userProfile?.id ?? "",
                attendeesCount: dataManager.attendees.count
            )
        }
        .fullScreenCover(isPresented: $showTransportModal) {
            TransportTabView(
                partyId: UUID(uuidString: partyId) ?? UUID(),
                currentUserId: UUID(uuidString: sessionManager.userProfile?.id ?? "") ?? UUID(),
                currentUserRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role ?? .attendee,
                destinationCity: dataManager.currentCity?.city,
                partyStartDate: partyManager.startDate,
                partyEndDate: partyManager.endDate
            )
        }
        .fullScreenCover(isPresented: $showLodgingModal) {
            LodgingTabView(
                partyId: UUID(uuidString: partyId) ?? UUID(),
                currentUserId: UUID(uuidString: sessionManager.userProfile?.id ?? "") ?? UUID(),
                currentUserRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role ?? .attendee
            )
        }
        .fullScreenCover(isPresented: $showItineraryModal) {
            ItineraryView()
                .environmentObject(partyManager)
                .environmentObject(sessionManager)
        }
        .fullScreenCover(isPresented: $showTasksModal) {
            TasksTabView(
                userRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role ?? .attendee
            )
        }
        .fullScreenCover(isPresented: $showPackingModal) {
            PackingTabView(
                partyId: UUID(uuidString: partyId) ?? UUID(),
                userRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role ?? .attendee,
                currentUserId: UUID(uuidString: sessionManager.userProfile?.id ?? "") ?? UUID()
            )
        }
        .fullScreenCover(isPresented: $showGamesModal) {
            GamesTabView(
                userRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role.rawValue ?? "attendee"
            )
        }
        .fullScreenCover(isPresented: $showGalleryModal) {
            GalleryTabView(
                userRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role ?? .attendee
            )
        }
        .fullScreenCover(isPresented: $showVendorsModal) {
            VendorsTabView(
                userRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role ?? .attendee
            )
        }
        .fullScreenCover(isPresented: $showShopModal) {
            ShopTabView(
                userRole: dataManager.attendees.first(where: { $0.isCurrentUser })?.role.rawValue ?? "attendee"
            )
        }
        .fullScreenCover(isPresented: $showCrewModal) {
            if let partyUUID = UUID(uuidString: partyId), let currentUserUUID = UUID(uuidString: sessionManager.userProfile?.id ?? "") {
                CrewTabView(
                    partyId: partyUUID,
                    currentUserId: currentUserUUID,
                    crewService: CrewService()
                )
                .environmentObject(dataManager)
            }
        }


        .onReceive(NotificationCenter.default.publisher(for: .refreshPartyData)) { _ in
            // Refresh data when party data is updated
            Task {
                await dataManager.refreshData()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("showChatModal"))) { _ in
            showChatModal = true
        }

        .onChange(of: partyManager.isLoaded) { isLoaded in
            // Load data when PartyManager becomes loaded
            if isLoaded {
                let currentUserId = sessionManager.userProfile?.id ?? ""
                Task {
                    print("🎯 PartyHubView: PartyManager loaded, starting data load for party \(partyId), currentUserId: \(currentUserId.isEmpty ? "<empty>" : currentUserId)")
                    await dataManager.loadAllData(
                        partyId: partyId,
                        currentUserId: currentUserId,
                        attendeesCount: partyManager.partySize
                    )
                    print("✅ PartyHubView: Data load completed for party \(partyId) [onChange isLoaded]")
                }
            }
        }
        .onAppear {
            // If PartyManager is already loaded when view appears, load data immediately
            if partyManager.isLoaded {
                let currentUserId = sessionManager.userProfile?.id ?? ""
                Task {
                    print("🎯 PartyHubView: onAppear load start for party \(partyId), currentUserId: \(currentUserId.isEmpty ? "<empty>" : currentUserId)")
                    await dataManager.loadAllData(
                        partyId: partyId,
                        currentUserId: currentUserId,
                        attendeesCount: partyManager.partySize
                    )
                    print("✅ PartyHubView: onAppear load completed for party \(partyId)")
                }
            } else {
                print("❌ PartyHubView: PartyManager not loaded - isLoaded: \(partyManager.isLoaded)")
            }
        }
        .onChange(of: sessionManager.userProfile?.id ?? "") { newId in
            // If user id becomes available later, refresh attendees so isCurrentUser flags are accurate
            guard partyManager.isLoaded else { return }
            print("🔄 PartyHubView: Detected userId change -> \(newId.isEmpty ? "<empty>" : newId). Reloading attendees.")
            Task {
                await dataManager.loadAttendees(partyId: partyId, currentUserId: newId)
            }
        }
        .onDisappear {
            // Clean up resources when view disappears
            dataManager.cleanup()
        }
    }
    
    private func refreshPartyData() async {
        AppLogger.data("PartyHubView: Pull-to-refresh initiated.")
        
        // Show loading state
        dataManager.isLoading = true
        
        let currentUserId = sessionManager.userProfile?.id ?? ""
        if !currentUserId.isEmpty {
            await dataManager.loadAllData(
                partyId: partyId,
                currentUserId: currentUserId,
                attendeesCount: partyManager.partySize
            )
            AppLogger.success("PartyHubView: Pull-to-refresh completed successfully.")
        } else {
            AppLogger.warning("PartyHubView: Cannot refresh data, no current user ID available.")
            dataManager.errorMessage = "Unable to refresh data. Please try again."
        }
        
        // Hide loading state
        dataManager.isLoading = false
    }
    
    // MARK: - Status pill helpers (match dashboard semantics)
    private func statusPillText() -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let now = Date()
        
        let start = partyManager.startDate
        let end = partyManager.endDate
        
        if start <= now && end >= now {
            return "LIVE"
        } else if start > now {
            let days = Calendar.current.dateComponents([.day], from: now, to: start).day ?? 0
            if days == 0 { return "Today" }
            if days == 1 { return "1 day" }
            return "\(days) days"
        } else {
            let days = Calendar.current.dateComponents([.day], from: end, to: now).day ?? 0
            if days == 0 { return "Yesterday" }
            if days == 1 { return "1 day ago" }
            return "\(days) days ago"
        }
    }
    
    private func getStatusBackgroundColor() -> Color { Color(hex: "#353E3E") }
}

// MARK: - Feature Preview Card Component
struct FeaturePreviewCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 32, height: 32)
                    .background(color.opacity(0.1))
                    .clipShape(Circle())
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.titleDark)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(20)
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    PartyHubView(partyId: "test-party-id")
        .environmentObject(PartyManager())
        .environmentObject(SessionManager())
}

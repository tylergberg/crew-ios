import Foundation
import SwiftUI
import Supabase

// MARK: - Feature Shims (compile-time placeholders)

// LodgingStore now implemented in Features/PartyDetail/Tabs/Lodging/Stores





@MainActor
final class TasksStore: ObservableObject {
    @Published var tasks: [TaskModel] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let client = SupabaseManager.shared.client
    
    func load(partyId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Use a custom decoder to handle date parsing with user data
            let response: [PartyTaskResponse] = try await client
                .from("tasks")
                .select("""
                    *,
                    assigned_user:profiles!tasks_assigned_to_fkey(
                        id,
                        full_name
                    ),
                    creator_user:profiles!tasks_created_by_fkey(
                        id,
                        full_name
                    )
                """)
                .eq("party_id", value: partyId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Convert to TaskModel with proper date handling
            let taskModels = response.compactMap { taskResponse -> TaskModel? in
                do {
                    return try TaskModel(from: taskResponse)
                } catch {
                    AppLogger.error("TasksStore: Error converting task \(taskResponse.id): \(error)")
                    return nil
                }
            }
            
            await MainActor.run {
                self.tasks = taskModels
            }
            
            AppLogger.success("TasksStore: Loaded \(taskModels.count) tasks for party \(partyId)")
        } catch {
            AppLogger.error("TasksStore: Error loading tasks: \(error)")
            await MainActor.run {
                self.errorMessage = "Failed to load tasks: \(error.localizedDescription)"
            }
        }
        
        isLoading = false
    }
    
    func addTask(_ task: TaskModel) async throws {
        let response: TaskModel = try await client
            .from("tasks")
            .insert(task)
            .select()
            .single()
            .execute()
            .value
        
        await MainActor.run {
            self.tasks.insert(response, at: 0)
        }
        
        AppLogger.success("TasksStore: Added task \(response.title)")
    }
    
    func updateTask(_ task: TaskModel) async throws {
        let response: TaskModel = try await client
            .from("tasks")
            .update(task)
            .eq("id", value: task.id)
            .select()
            .single()
            .execute()
            .value
        
        await MainActor.run {
            if let index = self.tasks.firstIndex(where: { $0.id == task.id }) {
                self.tasks[index] = response
            }
        }
        
        AppLogger.success("TasksStore: Updated task \(response.title)")
    }
    
    func deleteTask(_ taskId: UUID) async throws {
        try await client
            .from("tasks")
            .delete()
            .eq("id", value: taskId)
            .execute()
        
        await MainActor.run {
            self.tasks.removeAll { $0.id == taskId }
        }
        
        AppLogger.success("TasksStore: Deleted task \(taskId)")
    }
    
    func teardown() {
        tasks = []
        isLoading = false
        errorMessage = nil
    }
}

// MARK: - Vendors (implemented under Features/PartyDetail/Tabs/Vendors)
@MainActor
final class ItineraryService: ObservableObject {
    @Published var events: [ItineraryEvent] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func fetchEvents(for partyId: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: [ItineraryEvent] = try await supabase
                .from("itinerary_events")
                .select()
                .eq("party_id", value: partyId)
                .order("start_time", ascending: true)
                .execute()
                .value
            
            await MainActor.run {
                events = response
            }
            AppLogger.success("ItineraryService: Loaded \(events.count) events for party \(partyId)")
        } catch {
            AppLogger.error("ItineraryService: Error fetching events: \(error)")
            errorMessage = "Failed to load events: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func addEvent(_ event: ItineraryEvent) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: ItineraryEvent = try await supabase
                .from("itinerary_events")
                .insert(event)
                .select()
                .single()
                .execute()
                .value
            
            events.append(response)
            AppLogger.success("ItineraryService: Added event \(response.title)")
        } catch {
            AppLogger.error("ItineraryService: Error adding event: \(error)")
            errorMessage = "Failed to add event: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func updateEvent(_ event: ItineraryEvent) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let response: ItineraryEvent = try await supabase
                .from("itinerary_events")
                .update(event)
                .eq("id", value: event.id)
                .select()
                .single()
                .execute()
                .value
            
            if let index = events.firstIndex(where: { $0.id == event.id }) {
                events[index] = response
            }
            AppLogger.success("ItineraryService: Updated event \(response.title)")
        } catch {
            AppLogger.error("ItineraryService: Error updating event: \(error)")
            errorMessage = "Failed to update event: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func deleteEvent(_ eventId: UUID) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            try await supabase
                .from("itinerary_events")
                .delete()
                .eq("id", value: eventId)
                .execute()
            
            events.removeAll { $0.id == eventId }
            AppLogger.success("ItineraryService: Deleted event \(eventId)")
        } catch {
            AppLogger.error("ItineraryService: Error deleting event: \(error)")
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
            throw error
        }
        
        isLoading = false
    }
    
    func refreshEvents(for partyId: String) async {
        await fetchEvents(for: partyId)
    }
}
final class FlightsService {
    init(supabase: Any? = nil) {}
    func fetchFlights(partyId: UUID) async throws -> [String] { [] }
}
// PartyGamesService is now implemented in Shared/Services/PartyGamesService.swift
// GalleryService is now implemented in Features/PartyDetail/Tabs/Gallery/Services/GalleryService.swift

@MainActor
final class GalleryStore: ObservableObject {
    init(partyId: UUID, currentUserId: UUID) {}
    var items: [String] = []
}

final class CityLookupService {
    func fetchCityById(_ id: UUID) async throws -> CityCore? { CityCore(city: "") }
}




struct ItineraryView: View {
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var sessionManager: SessionManager
    
    var body: some View {
        ItineraryTabView(
            partyId: partyManager.partyId,
            currentUserId: sessionManager.userProfile?.id ?? "",
            userRole: partyManager.userRole ?? .attendee,
            cityTimezone: partyManager.timezone
        )
    }
}

struct VendorsTabView: View {
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var sessionManager: SessionManager
    let userRole: UserRole
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var vendorsByType: [(VendorType, [Vendor])] = []
    @State private var selectedVendor: Vendor?
    private let vendorService = VendorService()

    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 16) { ProgressView(); Text("Loading vendors…") }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 12) { Text("Failed to load vendors"); Text(errorMessage).font(.footnote).foregroundColor(.secondary) }
                        .padding()
                } else if vendorsByType.isEmpty {
                    EmptyVendors()
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            ForEach(vendorsByType, id: \.0) { pair in
                                VendorGrid(
                                    title: pair.0.displayName,
                                    vendors: pair.1,
                                    onSelect: { vendor in selectedVendor = vendor }
                                )
                            }
                        }
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { NotificationCenter.default.post(name: Notification.Name("dismissVendorsModal"), object: nil) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
        .onAppear { Task { await load() } }
        .sheet(item: $selectedVendor) { vendor in
            NavigationView {
                VendorDetailView(vendor: vendor)
                    .environmentObject(partyManager)
                    .environmentObject(sessionManager)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button(action: { selectedVendor = nil }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "chevron.left")
                                    Text("Explore")
                                }
                            }
                        }
                    }
            }
            .sheet(isPresented: Binding(get: { false }, set: { _ in })) { EmptyView() }
        }
    }

    private func load() async {
        guard let cityId = partyManager.cityId else {
            errorMessage = "Set a destination city to explore vendors."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let vendors = try await vendorService.fetchVendors(cityId: cityId)
            let grouped = Dictionary(grouping: vendors) { VendorType.from(types: $0.types) }
            let ordered: [(VendorType, [Vendor])] = VendorType.allCases.compactMap { type in
                if let list = grouped[type], !list.isEmpty { return (type, list) }
                return nil
            }
            vendorsByType = ordered
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ItineraryEvent: Identifiable, Codable, Hashable {
    let id: UUID
    let partyId: UUID
    let title: String
    let description: String?
    let location: String?
    let locationUrl: String?
    let imageUrl: String?
    let createdAt: Date
    let createdBy: UUID
    let updatedAt: Date?
    let cityId: UUID?
    let startTime: Date?
    let endTime: Date?
    let latitude: Double?
    let longitude: Double?
    
    init(
        id: UUID = UUID(),
        partyId: UUID,
        title: String,
        description: String? = nil,
        location: String? = nil,
        locationUrl: String? = nil,
        imageUrl: String? = nil,
        createdAt: Date = Date(),
        createdBy: UUID,
        updatedAt: Date? = nil,
        cityId: UUID? = nil,
        startTime: Date? = nil,
        endTime: Date? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil
    ) {
        self.id = id
        self.partyId = partyId
        self.title = title
        self.description = description
        self.location = location
        self.locationUrl = locationUrl
        self.imageUrl = imageUrl
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.updatedAt = updatedAt
        self.cityId = cityId
        self.startTime = startTime
        self.endTime = endTime
        self.latitude = latitude
        self.longitude = longitude
    }
    
    // CodingKeys to handle snake_case from database
    enum CodingKeys: String, CodingKey {
        case id, title, description, location
        case locationUrl = "location_url"
        case imageUrl = "image_url"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case updatedAt = "updated_at"
        case cityId = "city_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case partyId = "party_id"
        case latitude, longitude
    }
}

struct CityCore: Codable, Hashable {
    var city: String = ""
}

// MARK: - UI Shims

enum LodgingTheme {
    static let padding: CGFloat = 12
    static let smallPadding: CGFloat = 8
    static let spacing: CGFloat = 12
    static let tightSpacing: CGFloat = 6
    static let looseSpacing: CGFloat = 16
    static let cornerRadius: CGFloat = 16
    static let smallCornerRadius: CGFloat = 10

    static let headlineFont: Font = .headline
    static let bodyFont: Font = .body
    static let smallFont: Font = .caption

    static let primaryYellow: Color = .yellow
    static let backgroundYellow: Color = Color.yellow.opacity(0.1)
    static let textPrimary: Color = .primary
    static let textSecondary: Color = .secondary
    static let borderColor: Color = .black
}

enum CrewUtilities {
    static func getAvatarColor(for name: String) -> Color {
        // Simple deterministic color based on name hash
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .teal]
        let idx = abs(name.hashValue) % colors.count
        return colors[idx]
    }

    static func colorForRole(_ role: UserRole) -> Color {
        switch role {
        case .admin: return .red
        case .organizer: return .purple
        case .attendee: return .blue
        case .guest: return .gray
        }
    }

    static func colorForRsvpStatus(_ status: RsvpStatus) -> Color {
        switch status {
        case .guest: return .gray
        case .pending: return .orange
        case .confirmed: return .green
        case .declined: return .red
        }
    }
}

extension View {
    func applySubtleShadow() -> some View {
        shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

// MARK: - DateOnlyFormatter helper used in NotificationCenter
enum DateOnlyFormatter {
    static func displayString(from date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f.string(from: date)
    }
}



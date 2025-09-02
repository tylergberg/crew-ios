import Foundation
import SwiftUI

// MARK: - Feature Shims (compile-time placeholders)

// LodgingStore now implemented in Features/PartyDetail/Tabs/Lodging/Stores

@MainActor
final class TasksStore: ObservableObject {
    func load(partyId: UUID) async {}
    func teardown() {}
}

final class VendorService {
    func fetchVendors(cityId: UUID) async throws -> [String] { [] }
}
final class ItineraryService {
    var events: [ItineraryEvent] = []
    func fetchEvents(for partyId: String) async {}
}
final class FlightsService {
    init(supabase: Any? = nil) {}
    func fetchFlights(partyId: UUID) async throws -> [String] { [] }
}
final class PartyGamesService {
    static let shared = PartyGamesService()
    func fetchGames(partyId: String) async throws -> [String] { [] }
}
final class GalleryService {
    func fetchItems(partyId: UUID, page: Int, limit: Int) async throws -> [String] { [] }
}

@MainActor
final class GalleryStore: ObservableObject {
    init(partyId: UUID, currentUserId: UUID) {}
    var items: [String] = []
}

final class CityLookupService {
    func fetchCityById(_ id: UUID) async throws -> CityCore? { CityCore(city: "") }
}

// MARK: - Simple placeholder views used by fullScreenCovers
struct TransportTabView: View {
    let partyId: UUID
    let currentUserId: UUID
    let currentUserRole: UserRole
    let destinationCity: String?
    let partyStartDate: Date
    let partyEndDate: Date
    var body: some View { Text("Transport (placeholder)") }
}


struct ItineraryView: View {
    @EnvironmentObject var partyManager: PartyManager
    @EnvironmentObject var sessionManager: SessionManager
    var body: some View { Text("Itinerary (placeholder)") }
}

struct VendorsTabView: View {
    let userRole: UserRole
    var body: some View { Text("Vendors (placeholder)") }
}

struct ItineraryEvent: Identifiable, Codable, Hashable {
    let id: UUID = UUID()
    var startDate: Date? = nil
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



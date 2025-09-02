import Foundation

struct FlightPassenger: Identifiable, Codable, Hashable {
    let id: UUID
    let flightId: UUID
    let userId: UUID
    let partyId: UUID
    let createdAt: Date
    
    // This will be populated when joining with profiles
    var profile: TransportProfile?
    
    // Track if this is the current user
    var isCurrentUser: Bool = false
    
    init(
        id: UUID = UUID(),
        flightId: UUID,
        userId: UUID,
        partyId: UUID,
        createdAt: Date = Date(),
        profile: TransportProfile? = nil,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.flightId = flightId
        self.userId = userId
        self.partyId = partyId
        self.createdAt = createdAt
        self.profile = profile
        self.isCurrentUser = isCurrentUser
    }
    
    // CodingKeys to handle snake_case from database
    enum CodingKeys: String, CodingKey {
        case id, flightId = "flight_id", userId = "user_id"
        case partyId = "party_id", createdAt = "created_at"
    }
    
    // MARK: - Hashable & Equatable
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: FlightPassenger, rhs: FlightPassenger) -> Bool {
        lhs.id == rhs.id
    }
}

// Extension to help with profile display
extension FlightPassenger {
    var displayName: String {
        profile?.fullName ?? "Unknown"
    }
    
    var initials: String {
        profile?.initials ?? "??"
    }
    
    var avatarUrl: String? {
        profile?.avatarUrl
    }
}

import Foundation

// Minimal placeholders to restore build. Replace with real implementations as we rebuild PartyHub.

enum UserRole: String, Codable, CaseIterable, Equatable {
    case attendee
    case organizer
    case admin
    case guest
}

enum RsvpStatus: String, Codable, CaseIterable, Equatable {
    case guest
    case confirmed
    case declined
    case pending
}

extension RsvpStatus {
    var displayName: String {
        switch self {
        case .guest: return "Guest"
        case .confirmed: return "Confirmed"
        case .declined: return "Declined"
        case .pending: return "Pending"
        }
    }
}

extension UserRole {
    var displayName: String {
        switch self {
        case .attendee: return "Attendee"
        case .organizer: return "Organizer"
        case .admin: return "Admin"
        case .guest: return "Guest"
        }
    }
}

struct PartyAttendee: Identifiable, Hashable, Codable {
    let id: UUID
    var userId: String
    var partyId: String
    var fullName: String
    var email: String?
    var avatarUrl: String?
    var role: UserRole
    var rsvpStatus: RsvpStatus
    var specialRole: String?
    var invitedAt: Date?
    var respondedAt: Date?
    var isCurrentUser: Bool

    var initials: String {
        let comps = fullName.split(separator: " ")
        let first = comps.first?.first.map { String($0) } ?? ""
        let last = comps.dropFirst().first?.first.map { String($0) } ?? ""
        return (first + last).uppercased()
    }

    init(
        id: UUID = UUID(),
        userId: String = UUID().uuidString,
        partyId: String = UUID().uuidString,
        fullName: String,
        email: String? = nil,
        avatarUrl: String? = nil,
        role: UserRole = .attendee,
        rsvpStatus: RsvpStatus = .guest,
        specialRole: String? = nil,
        invitedAt: Date? = nil,
        respondedAt: Date? = nil,
        isCurrentUser: Bool = false
    ) {
        self.id = id
        self.userId = userId
        self.partyId = partyId
        self.fullName = fullName
        self.email = email
        self.avatarUrl = avatarUrl
        self.role = role
        self.rsvpStatus = rsvpStatus
        self.specialRole = specialRole
        self.invitedAt = invitedAt
        self.respondedAt = respondedAt
        self.isCurrentUser = isCurrentUser
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case partyId
        case fullName
        case email
        case avatarUrl
        case role
        case rsvpStatus
        case specialRole
        case invitedAt
        case respondedAt
        case isCurrentUser
    }
}



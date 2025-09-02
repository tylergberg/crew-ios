import Foundation

struct Transportation: Identifiable, Codable, Hashable {
    let id: UUID
    let partyId: UUID
    let type: TransportationType
    let title: String
    let description: String?
    let date: Date?
    let time: Date?
    let meetingPoint: String?
    let capacity: Int?
    let url: String?
    let createdAt: Date
    let createdBy: UUID
    
    init(
        id: UUID = UUID(),
        partyId: UUID,
        type: TransportationType,
        title: String,
        description: String? = nil,
        date: Date? = nil,
        time: Date? = nil,
        meetingPoint: String? = nil,
        capacity: Int? = nil,
        url: String? = nil,
        createdAt: Date = Date(),
        createdBy: UUID
    ) {
        self.id = id
        self.partyId = partyId
        self.type = type
        self.title = title
        self.description = description
        self.date = date
        self.time = time
        self.meetingPoint = meetingPoint
        self.capacity = capacity
        self.url = url
        self.createdAt = createdAt
        self.createdBy = createdBy
    }
    
    // CodingKeys to handle snake_case from database
    enum CodingKeys: String, CodingKey {
        case id, partyId = "party_id", type, title, description, date, time
        case meetingPoint = "meeting_point", capacity, url
        case createdAt = "created_at", createdBy = "created_by"
    }
}

enum TransportationType: String, Codable, CaseIterable {
    case flight = "flight"
    case carpool = "carpool"
    case local = "local"
    
    var displayName: String {
        switch self {
        case .flight:
            return "Flight"
        case .carpool:
            return "Carpool"
        case .local:
            return "Local Transport"
        }
    }
    
    var icon: String {
        switch self {
        case .flight:
            return "airplane"
        case .carpool:
            return "car.fill"
        case .local:
            return "bus.fill"
        }
    }
}

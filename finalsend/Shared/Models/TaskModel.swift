import Foundation

struct TaskModel: Identifiable, Codable, Equatable {
    let id: UUID
    let partyId: UUID
    var title: String
    var description: String?
    var assignedTo: UUID?
    var status: TaskStatus
    var dueDate: Date?
    var completed: Bool
    var createdBy: UUID
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case title
        case description
        case assignedTo = "assigned_to"
        case status
        case dueDate = "due_date"
        case completed
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Patch model for UI save flows
struct TaskModelPatch: Codable {
    var title: String?
    var description: String?
    var assignedTo: UUID?
    var status: TaskStatus?
    var dueDate: Date?
}



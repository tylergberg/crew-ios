import Foundation

// MARK: - Party Task Response from Database
struct PartyTaskResponse: Codable {
    let id: String
    let party_id: String
    let title: String
    let description: String?
    let assigned_to: String?
    let status: String?
    let due_date: String?
    let completed: Bool?
    let created_by: String
    let created_at: String
    let updated_at: String?
    
    // Joined user data
    let assigned_user: UserProfileResponse?
    let creator_user: UserProfileResponse?
}

struct UserProfileResponse: Codable {
    let id: String
    let full_name: String?
}

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
    
    // User display names
    var assignedToName: String?
    var createdByName: String?

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
    
    // Regular initializer for creating new tasks
    init(
        id: UUID,
        partyId: UUID,
        title: String,
        description: String? = nil,
        assignedTo: UUID? = nil,
        status: TaskStatus = .todo,
        dueDate: Date? = nil,
        completed: Bool = false,
        createdBy: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.partyId = partyId
        self.title = title
        self.description = description
        self.assignedTo = assignedTo
        self.status = status
        self.dueDate = dueDate
        self.completed = completed
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        
        // Initialize user names as nil for regular initializer
        self.assignedToName = nil
        self.createdByName = nil
    }
    
    // Initialize from PartyTaskResponse with proper date parsing
    init(from response: PartyTaskResponse) throws {
        guard let id = UUID(uuidString: response.id),
              let partyId = UUID(uuidString: response.party_id),
              let createdBy = UUID(uuidString: response.created_by) else {
            throw TaskModelError.invalidUUID
        }
        
        self.id = id
        self.partyId = partyId
        self.title = response.title
        self.description = response.description
        self.assignedTo = response.assigned_to.flatMap { UUID(uuidString: $0) }
        self.status = TaskStatus(rawValue: response.status ?? "todo") ?? .todo
        self.completed = response.completed ?? false
        self.createdBy = createdBy
        
        // Parse dates with proper error handling
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Parse created_at (required field)
        if let createdDate = dateFormatter.date(from: response.created_at) {
            self.createdAt = createdDate
        } else {
            self.createdAt = Date()
        }
        
        // Parse updated_at (optional field)
        if let updatedDateString = response.updated_at,
           let updatedDate = dateFormatter.date(from: updatedDateString) {
            self.updatedAt = updatedDate
        } else {
            self.updatedAt = Date()
        }
        
        // Handle due_date parsing
        if let dueDateString = response.due_date {
            // Try ISO8601 first
            if let dueDate = dateFormatter.date(from: dueDateString) {
                self.dueDate = dueDate
            } else {
                // Try simple date format (YYYY-MM-DD)
                let simpleFormatter = DateFormatter()
                simpleFormatter.dateFormat = "yyyy-MM-dd"
                simpleFormatter.timeZone = TimeZone.current
                self.dueDate = simpleFormatter.date(from: dueDateString)
            }
        } else {
            self.dueDate = nil
        }
        
        // Set user display names
        self.assignedToName = response.assigned_user?.full_name
        self.createdByName = response.creator_user?.full_name
    }
}

enum TaskModelError: Error {
    case invalidUUID
}

// Patch model for UI save flows
struct TaskModelPatch: Codable {
    var title: String?
    var description: String?
    var assignedTo: UUID?
    var status: TaskStatus?
    var dueDate: Date?
}



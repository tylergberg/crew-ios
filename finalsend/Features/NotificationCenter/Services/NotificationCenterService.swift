import Foundation
import Supabase

// Helper for decoding Any types
struct AnyCodable: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode value")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case is NSNull:
            try container.encodeNil()
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: encoder.codingPath, debugDescription: "Cannot encode value"))
        }
    }
}



@MainActor
class NotificationCenterService: ObservableObject {
    private let client = SupabaseManager.shared.client
    
    // MARK: - Task Management
    
    /// Get all tasks assigned to the current user across all parties
    func getUserTasks(
        status: TaskStatus? = nil,
        partyId: UUID? = nil,
        showOverdue: Bool = false
    ) async throws -> [TaskWithPartyContext] {
        
        guard let currentUserId = AuthManager.shared.currentUserId else {
            throw NotificationCenterError.userNotAuthenticated
        }
        
        print("🔍 NotificationCenterService: Fetching tasks for user: \(currentUserId)")
        
        var query = client
            .from("tasks")
            .select("""
                *,
                parties!tasks_party_id_fkey(
                    id,
                    name,
                    start_date,
                    end_date,
                    cover_image_url
                ),
                creator:profiles!tasks_created_by_fkey(
                    id,
                    full_name
                )
            """)
            .eq("assigned_to", value: currentUserId)
        
        // Apply filters
        if let status = status {
            query = query.eq("status", value: status.rawValue)
        }
        
        if let partyId = partyId {
            query = query.eq("party_id", value: partyId)
        }
        
        if showOverdue {
            query = query.lt("due_date", value: Date().ISO8601Format())
                .neq("status", value: "completed")
        }
        
        let response: [TaskWithPartyResponse] = try await query
            .order("due_date", ascending: true)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        print("🔍 NotificationCenterService: Found \(response.count) tasks")
        
        return response.map { TaskWithPartyContext(from: $0) }
    }
    
    /// Update task status
    func updateTaskStatus(_ taskId: UUID, status: TaskStatus) async throws {
        try await client
            .from("tasks")
            .update([
                "status": status.rawValue,
                "completed": String(status == .completed),
                "updated_at": Date().ISO8601Format()
            ])
            .eq("id", value: taskId)
            .execute()
    }
    
    /// Mark task as complete
    func completeTask(_ taskId: UUID) async throws {
        try await updateTaskStatus(taskId, status: .completed)
    }
    
    /// Get unread task count (tasks that are not completed)
    func getUnreadTaskCount() async throws -> Int {
        guard let currentUserId = AuthManager.shared.currentUserId else {
            return 0
        }
        
        struct TaskCountResponse: Codable {
            let id: UUID
        }
        
        let response: [TaskCountResponse] = try await client
            .from("tasks")
            .select("id")
            .eq("assigned_to", value: currentUserId)
            .neq("status", value: "completed")
            .execute()
            .value
        
        return response.count
    }
}

// MARK: - Response Models

struct TaskWithPartyResponse: Codable {
    let id: UUID
    let partyId: UUID
    let title: String
    let description: String?
    let assignedTo: UUID?
    let status: String
    let dueDate: String?
    let completed: Bool
    let createdBy: UUID
    let createdAt: Date
    let updatedAt: Date
    let taskType: String?
    let gameId: UUID?
    let metadata: [String: Any]?
    
    // Joined party data
    let parties: PartyData?
    let creator: CreatorData?
    
    struct PartyData: Codable {
        let id: UUID
        let name: String
        let startDate: String?
        let endDate: String?
        let coverImageUrl: String?
        
        enum CodingKeys: String, CodingKey {
            case id, name
            case startDate = "start_date"
            case endDate = "end_date"
            case coverImageUrl = "cover_image_url"
        }
    }
    
    struct CreatorData: Codable {
        let id: UUID
        let fullName: String?
        
        enum CodingKeys: String, CodingKey {
            case id
            case fullName = "full_name"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case id, title, description, status, completed
        case partyId = "party_id"
        case assignedTo = "assigned_to"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case createdBy = "created_by"
        case updatedAt = "updated_at"
        case taskType = "task_type"
        case gameId = "game_id"
        case metadata
        case parties, creator
    }
    
    // Custom decoding to handle metadata as either dictionary or string
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        partyId = try container.decode(UUID.self, forKey: .partyId)
        title = try container.decode(String.self, forKey: .title)
        description = try container.decodeIfPresent(String.self, forKey: .description)
        assignedTo = try container.decodeIfPresent(UUID.self, forKey: .assignedTo)
        status = try container.decode(String.self, forKey: .status)
        dueDate = try container.decodeIfPresent(String.self, forKey: .dueDate)
        completed = try container.decode(Bool.self, forKey: .completed)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        taskType = try container.decodeIfPresent(String.self, forKey: .taskType)
        gameId = try container.decodeIfPresent(UUID.self, forKey: .gameId)
        parties = try container.decodeIfPresent(PartyData.self, forKey: .parties)
        creator = try container.decodeIfPresent(CreatorData.self, forKey: .creator)
        
        // Handle metadata - decode as Any first, then process
        do {
            if let metadataValue = try container.decodeIfPresent(AnyCodable.self, forKey: .metadata) {
                if let dict = metadataValue.value as? [String: Any] {
                    metadata = dict
                } else if let string = metadataValue.value as? String {
                    // Parse JSON string to dictionary
                    if let data = string.data(using: .utf8),
                       let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        metadata = parsed
                    } else {
                        metadata = nil
                    }
                } else {
                    metadata = nil
                }
            } else {
                metadata = nil
            }
        } catch {
            metadata = nil
        }
    }
    
    // Custom encoding - encode metadata as JSON string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(partyId, forKey: .partyId)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(assignedTo, forKey: .assignedTo)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encode(completed, forKey: .completed)
        try container.encode(createdBy, forKey: .createdBy)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encode(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(taskType, forKey: .taskType)
        try container.encodeIfPresent(gameId, forKey: .gameId)
        try container.encodeIfPresent(parties, forKey: .parties)
        try container.encodeIfPresent(creator, forKey: .creator)
        
        // Encode metadata as JSON string
        if let metadata = metadata {
            if let data = try? JSONSerialization.data(withJSONObject: metadata),
               let string = String(data: data, encoding: .utf8) {
                try container.encode(string, forKey: .metadata)
            }
        }
    }
    
    // Computed properties for easier access
    var partyName: String {
        return parties?.name ?? "Unknown Party"
    }
    
    var partyStartDate: String? {
        return parties?.startDate
    }
    
    var partyEndDate: String? {
        return parties?.endDate
    }
    
    var partyCoverImageUrl: String? {
        return parties?.coverImageUrl
    }
    
    var creatorId: UUID {
        return creator?.id ?? createdBy
    }
    
    var creatorFullName: String? {
        return creator?.fullName
    }
}

private struct TaskResponse: Codable {
    let id: UUID
    let partyId: UUID
    let title: String
    let description: String?
    let assignedTo: UUID?
    let status: String
    let dueDate: String?
    let completed: Bool
    let createdBy: UUID
    let createdAt: Date
    let updatedAt: Date
    
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

private struct PartyResponse: Codable {
    let id: UUID
    let name: String
    let startDate: String?
    let endDate: String?
    let coverImageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case coverImageUrl = "cover_image_url"
    }
}

private struct CreatorResponse: Codable {
    let id: UUID
    let fullName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
    }
}

// MARK: - Task with Party Context

struct TaskWithPartyContext: Identifiable, Codable {
    let id: UUID
    let task: TaskModel
    let party: PartySummary
    let creator: CreatorSummary
    
    init(task: TaskModel, party: PartySummary, creator: CreatorSummary) {
        self.id = task.id
        self.task = task
        self.party = party
        self.creator = creator
    }
    
    init(from response: TaskWithPartyResponse) {
        self.id = response.id
        print("🔍 Creating TaskWithPartyContext for task: \(response.title), status: \(response.status)")
        
        // Metadata is already parsed in TaskWithPartyResponse
        let parsedMetadata = response.metadata
        
        self.task = TaskModel(
            id: response.id,
            partyId: response.partyId,
            title: response.title,
            description: response.description,
            assignedTo: response.assignedTo,
            status: TaskStatus(rawValue: response.status) ?? .todo,
            dueDate: response.dueDate != nil ? dateOnlyFormatter().date(from: response.dueDate!) : nil,
            completed: response.completed,
            createdBy: response.createdBy,
            createdAt: response.createdAt,
            updatedAt: response.updatedAt,
            taskType: response.taskType,
            gameId: response.gameId,
            metadata: parsedMetadata
        )
        self.party = PartySummary(
            id: response.partyId,
            title: response.partyName,
            startDate: response.partyStartDate != nil ? ISO8601DateFormatter().date(from: response.partyStartDate!) : nil,
            endDate: response.partyEndDate != nil ? ISO8601DateFormatter().date(from: response.partyEndDate!) : nil,
            coverImageUrl: response.partyCoverImageUrl
        )
        self.creator = CreatorSummary(
            id: response.creatorId,
            name: response.creatorFullName ?? "Unknown"
        )
    }
    
    struct PartySummary: Codable {
        let id: UUID
        let title: String
        let startDate: Date?
        let endDate: Date?
        let coverImageUrl: String?
    }
    
    struct CreatorSummary: Codable {
        let id: UUID
        let name: String
    }
}

// MARK: - Errors

enum NotificationCenterError: LocalizedError {
    case userNotAuthenticated
    case taskNotFound
    case updateFailed
    case fetchFailed
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .taskNotFound:
            return "Task not found"
        case .updateFailed:
            return "Failed to update task"
        case .fetchFailed:
            return "Failed to fetch tasks"
        }
    }
}

// MARK: - Utilities

// Use existing DateOnlyFormatter from the app
private func dateOnlyFormatter() -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.timeZone = TimeZone.current
    return formatter
}

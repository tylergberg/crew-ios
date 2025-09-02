import Foundation

enum TaskStatus: String, CaseIterable, Codable {
    case todo = "todo"
    case inProgress = "in-progress"
    case completed = "completed"
    
    var displayName: String {
        switch self {
        case .todo:
            return "To Do"
        case .inProgress:
            return "In Progress"
        case .completed:
            return "Completed"
        }
    }
    
    var color: String {
        switch self {
        case .todo:
            return "bg-[#FDF3E7] text-[#401B17] border border-black"
        case .inProgress:
            return "bg-[#4A81E8]/10 text-[#4A81E8] border border-black"
        case .completed:
            return "bg-[#14342F]/10 text-[#14342F] border border-black"
        }
    }
}


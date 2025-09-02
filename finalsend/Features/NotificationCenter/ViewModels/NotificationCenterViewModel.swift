import Foundation
import SwiftUI

@MainActor
class NotificationCenterViewModel: ObservableObject {
    @Published var tasks: [TaskWithPartyContext] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var selectedFilter: TaskFilter = .todo
    @Published var unreadCount = 0
    @Published var todoCount = 0
    @Published var inProgressCount = 0
    @Published var completedCount = 0
    
    private let service = NotificationCenterService()
    
    var filteredTasks: [TaskWithPartyContext] {
        print("🔍 Filtering tasks for filter: \(selectedFilter)")
        print("🔍 Total tasks: \(tasks.count)")
        
        let filtered: [TaskWithPartyContext]
        switch selectedFilter {
        case .todo:
            filtered = tasks.filter { $0.task.status == .todo }
            print("🔍 Todo filter: found \(filtered.count) tasks")
        case .inProgress:
            filtered = tasks.filter { $0.task.status == .inProgress }
            print("🔍 InProgress filter: found \(filtered.count) tasks")
        case .completed:
            filtered = tasks.filter { $0.task.status == .completed }
            print("🔍 Completed filter: found \(filtered.count) tasks")
        }
        
        return filtered
    }
    
    var hasTasks: Bool {
        return !tasks.isEmpty
    }
    
    var hasFilteredTasks: Bool {
        return !filteredTasks.isEmpty
    }
    
    func loadTasks() async {
        isLoading = true
        errorMessage = nil
        
        print("🔍 NotificationCenterViewModel: Loading tasks...")
        print("🔍 Current selectedFilter: \(selectedFilter)")
        
        do {
            tasks = try await service.getUserTasks()
            unreadCount = try await service.getUnreadTaskCount()
            print("🔍 NotificationCenterViewModel: Loaded \(tasks.count) tasks, unread count: \(unreadCount)")
            
            // Debug: Print task statuses
            let statusCounts = Dictionary(grouping: tasks, by: { $0.task.status })
                .mapValues { $0.count }
            print("🔍 Task status counts: \(statusCounts)")
            
            // Debug: Print individual task statuses
            for (index, task) in tasks.prefix(5).enumerated() {
                print("🔍 Task \(index): status = \(task.task.status), rawValue = \(task.task.status.rawValue)")
            }
            
            // Update published count properties
            todoCount = tasks.filter { $0.task.status == .todo }.count
            inProgressCount = tasks.filter { $0.task.status == .inProgress }.count
            completedCount = tasks.filter { $0.task.status == .completed }.count
            
            print("🔍 Updated counts - todo: \(todoCount), inProgress: \(inProgressCount), completed: \(completedCount)")
        } catch {
            errorMessage = error.localizedDescription
            print("❌ NotificationCenterViewModel: Error loading tasks: \(error)")
        }
        
        isLoading = false
    }
    
    func updateTaskStatus(_ taskId: UUID, status: TaskStatus) async {
        do {
            try await service.updateTaskStatus(taskId, status: status)
            await loadTasks() // Refresh the list
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func completeTask(_ taskId: UUID) async {
        await updateTaskStatus(taskId, status: .completed)
    }
    
    func refreshTasks() async {
        await loadTasks()
    }
}

// MARK: - Task Filter

enum TaskFilter: String, CaseIterable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case completed = "Completed"
    
    var icon: String {
        switch self {
        case .todo: return "circle"
        case .inProgress: return "clock"
        case .completed: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .todo: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
}

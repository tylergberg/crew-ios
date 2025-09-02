import SwiftUI

struct NotificationCenterTaskListView: View {
    let tasks: [TaskWithPartyContext]
    let onTaskTapped: (TaskWithPartyContext) -> Void
    let onTaskStatusChanged: (TaskWithPartyContext, TaskStatus) -> Void
    
    var body: some View {
        let _ = print("🔍 NotificationCenterTaskListView: Received \(tasks.count) tasks")
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(tasks) { taskContext in
                    NotificationCenterTaskRowView(
                        taskContext: taskContext,
                        onTap: { onTaskTapped(taskContext) },
                        onStatusChange: { newStatus in
                            onTaskStatusChanged(taskContext, newStatus)
                        }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 8)
        }
        .background(Color(.systemGroupedBackground))
    }
}

struct NotificationCenterTaskRowView: View {
    let taskContext: TaskWithPartyContext
    let onTap: () -> Void
    let onStatusChange: (TaskStatus) -> Void
    
    @State private var showingStatusMenu = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Party context header
            HStack(spacing: 8) {
                // Party image
                AsyncImage(url: URL(string: taskContext.party.coverImageUrl ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                
                // Party info
                VStack(alignment: .leading, spacing: 1) {
                    Text(taskContext.party.title)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    if let startDate = taskContext.party.startDate {
                        Text(startDate, style: .date)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
            }
            
            // Task title
            Text(taskContext.task.title)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(2)
                .foregroundColor(.primary)
            
            // Task description (if exists)
            if let description = taskContext.task.description, !description.isEmpty {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            // Task metadata and actions
            HStack(spacing: 8) {
                // Due date
                if let dueDate = taskContext.task.dueDate {
                    DueDateBadge(dueDate: dueDate)
                }
                
                // Creator info
                Text("Created by: \(taskContext.creator.name)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Spacer()
                
                // Chevron to indicate tappable
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - Status Badge

struct StatusBadge: View {
    let status: TaskStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.1))
            .foregroundColor(statusColor)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch status {
        case .todo:
            return .orange
        case .inProgress:
            return .blue
        case .completed:
            return .green
        }
    }
}

// MARK: - Due Date Badge

struct DueDateBadge: View {
    let dueDate: Date
    
    private var isOverdue: Bool {
        return dueDate < Date()
    }
    
    private var isToday: Bool {
        return Calendar.current.isDateInToday(dueDate)
    }
    
    private var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(dueDate)
    }
    
    private var displayText: String {
        if isOverdue {
            return "Overdue"
        } else if isToday {
            return "Due Today"
        } else if isTomorrow {
            return "Due Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return "Due \(formatter.string(from: dueDate))"
        }
    }
    
    private var badgeColor: Color {
        if isOverdue {
            return .red
        } else if isToday {
            return .orange
        } else if isTomorrow {
            return .yellow
        } else {
            return .blue
        }
    }
    
    var body: some View {
        HStack(spacing: 2) {
            Image(systemName: "calendar")
                .font(.caption2)
            
            Text(displayText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(badgeColor.opacity(0.1))
        .foregroundColor(badgeColor)
        .clipShape(Capsule())
    }
}

// MARK: - TaskStatus Extension
// Using the displayName property from TaskStatus in TaskModel.swift

#Preview {
    NotificationCenterTaskListView(
        tasks: [],
        onTaskTapped: { _ in },
        onTaskStatusChanged: { _, _ in }
    )
}

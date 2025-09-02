import SwiftUI

struct TasksTabView: View {
    let userRole: UserRole
    let partyId: UUID
    let currentUserId: UUID
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var tasksStore = TasksStore()
    @State private var showingAddTask = false
    @State private var selectedTask: TaskModel?
    @State private var searchText = ""
    @State private var selectedFilter: TaskStatus? = nil
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with search and filter
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.secondary)
                        
                        TextField("Search tasks...", text: $searchText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                    }
                    .padding(.horizontal)
                    
                    // Filter buttons
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            FilterButton(
                                title: "All",
                                isSelected: selectedFilter == nil,
                                action: { selectedFilter = nil }
                            )
                            
                            ForEach(TaskStatus.allCases, id: \.self) { status in
                                FilterButton(
                                    title: status.displayName,
                                    isSelected: selectedFilter == status,
                                    action: { selectedFilter = status }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemBackground))
                
                // Tasks content
                if tasksStore.isLoading {
                    Spacer()
                    ProgressView("Loading tasks...")
                    Spacer()
                } else if filteredTasks.isEmpty {
                    Spacer()
                    EmptyTasksView(
                        userRole: userRole,
                        onAddTask: { showingAddTask = true }
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 20) {
                            // Show columns based on filter selection
                            if selectedFilter == nil {
                                // Show all columns when no filter is selected
                                TaskColumn(
                                    title: "To Do",
                                    tasks: todoTasks,
                                    backgroundColor: Color.orange.opacity(0.1),
                                    onTaskTap: { task in
                                        selectedTask = task
                                    }
                                )
                                
                                TaskColumn(
                                    title: "In Progress",
                                    tasks: inProgressTasks,
                                    backgroundColor: Color.blue.opacity(0.1),
                                    onTaskTap: { task in
                                        selectedTask = task
                                    }
                                )
                                
                                TaskColumn(
                                    title: "Completed",
                                    tasks: completedTasks,
                                    backgroundColor: Color.green.opacity(0.1),
                                    onTaskTap: { task in
                                        selectedTask = task
                                    }
                                )
                            } else {
                                // Show only the selected filter column
                                switch selectedFilter {
                                case .todo:
                                    TaskColumn(
                                        title: "",
                                        tasks: todoTasks,
                                        backgroundColor: Color.orange.opacity(0.1),
                                        onTaskTap: { task in
                                            selectedTask = task
                                        }
                                    )
                                case .inProgress:
                                    TaskColumn(
                                        title: "",
                                        tasks: inProgressTasks,
                                        backgroundColor: Color.blue.opacity(0.1),
                                        onTaskTap: { task in
                                            selectedTask = task
                                        }
                                    )
                                case .completed:
                                    TaskColumn(
                                        title: "",
                                        tasks: completedTasks,
                                        backgroundColor: Color.green.opacity(0.1),
                                        onTaskTap: { task in
                                            selectedTask = task
                                        }
                                    )
                                case nil:
                                    // This case should never happen since we're in the else block
                                    // but Swift requires it for exhaustiveness
                                    EmptyView()
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Back") {
                    // Dismiss the fullScreenCover
                    dismiss()
                },
                trailing: (userRole == .admin || userRole == .organizer) ? Button("Add") {
                    showingAddTask = true
                } : nil
            )
        }
        .onAppear {
            Task {
                await tasksStore.load(partyId: partyId)
            }
        }
        .sheet(isPresented: $showingAddTask) {
            AddTaskView(
                partyId: partyId,
                currentUserId: currentUserId,
                onTaskAdded: { task in
                    Task {
                        try? await tasksStore.addTask(task)
                    }
                }
            )
        }
        .sheet(item: $selectedTask) { task in
            TaskDetailView(
                task: task,
                userRole: userRole,
                onTaskUpdated: { updatedTask in
                    Task {
                        try? await tasksStore.updateTask(updatedTask)
                    }
                },
                onTaskDeleted: { taskId in
                    Task {
                        try? await tasksStore.deleteTask(taskId)
                    }
                }
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var filteredTasks: [TaskModel] {
        var tasks = tasksStore.tasks
        
        // Apply search filter
        if !searchText.isEmpty {
            tasks = tasks.filter { task in
                task.title.localizedCaseInsensitiveContains(searchText) ||
                (task.description?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Apply status filter
        if let selectedFilter = selectedFilter {
            tasks = tasks.filter { $0.status == selectedFilter }
        }
        
        return tasks
    }
    
    private var todoTasks: [TaskModel] {
        filteredTasks.filter { $0.status == .todo }
    }
    
    private var inProgressTasks: [TaskModel] {
        filteredTasks.filter { $0.status == .inProgress }
    }
    
    private var completedTasks: [TaskModel] {
        filteredTasks.filter { $0.status == .completed }
    }
}

// MARK: - Supporting Views

struct FilterButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

struct TaskColumn: View {
    let title: String
    let tasks: [TaskModel]
    let backgroundColor: Color
    let onTaskTap: (TaskModel) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Column header - only show if title is not empty
            if !title.isEmpty {
                HStack {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text("\(tasks.count)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(backgroundColor)
                .cornerRadius(12)
            }
            
            // Task cards
            LazyVStack(spacing: 8) {
                ForEach(tasks) { task in
                    TaskCard(task: task, onTap: { onTaskTap(task) })
                }
            }
        }
    }
}

struct TaskCard: View {
    let task: TaskModel
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                // Task title and status
                HStack {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    Text(task.status.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(statusColor.opacity(0.1))
                        .foregroundColor(statusColor)
                        .cornerRadius(8)
                }
                
                // Task description
                if let description = task.description, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                
                // Task metadata
                HStack {
                    // Assignee info
                    if let assignedToName = task.assignedToName, !assignedToName.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text(assignedToName)
                                .font(.caption2)
                        }
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    } else if task.assignedTo != nil {
                        HStack(spacing: 4) {
                            Image(systemName: "person.fill")
                                .font(.caption2)
                            Text("Unknown User")
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "person.slash")
                                .font(.caption2)
                            Text("Unassigned")
                                .font(.caption2)
                        }
                        .foregroundColor(.gray)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    // Due date
                    if let dueDate = task.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text(dueDate, style: .date)
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
                    }
                    
                    // Completion status
                    if task.completed {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var statusColor: Color {
        switch task.status {
        case .todo:
            return .orange
        case .inProgress:
            return .blue
        case .completed:
            return .green
        }
    }
}



struct EmptyTasksView: View {
    let userRole: UserRole
    let onAddTask: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.square")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No tasks yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Get started by creating your first task")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if userRole == .admin || userRole == .organizer {
                Button("Add Task") {
                    onAddTask()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    TasksTabView(
        userRole: .organizer,
        partyId: UUID(),
        currentUserId: UUID()
    )
}


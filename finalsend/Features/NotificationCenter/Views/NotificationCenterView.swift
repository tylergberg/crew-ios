import SwiftUI

// MARK: - Task Management View

struct NotificationCenterView: View {
    @StateObject private var viewModel = NotificationCenterViewModel()
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appNavigator: AppNavigator
    @State private var selectedTask: TaskWithPartyContext?
    @State private var showingTaskEdit = false
    
    var body: some View {
        NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header with filter tabs
                    NotificationCenterHeaderView(
                        selectedFilter: $viewModel.selectedFilter,
                        viewModel: viewModel
                    )
                    
                    // Task list
                    let _ = print("🔍 Main view conditions - isLoading: \(viewModel.isLoading), hasTasks: \(viewModel.hasTasks), hasFilteredTasks: \(viewModel.hasFilteredTasks)")
                    if viewModel.isLoading {
                        NotificationCenterLoadingView()
                    } else if !viewModel.hasTasks {
                        EmptyStateView()
                    } else if !viewModel.hasFilteredTasks {
                        EmptyFilterStateView(filter: viewModel.selectedFilter)
                    } else {
                        NotificationCenterTaskListView(
                            tasks: viewModel.filteredTasks,
                            onTaskTapped: { task in
                                selectedTask = task
                                showingTaskEdit = true
                            },
                            onTaskStatusChanged: { task, newStatus in
                                Task {
                                    await viewModel.updateTaskStatus(task.task.id, status: newStatus)
                                    // Post notification to refresh dashboard count
                                    NotificationCenter.default.post(name: Notification.Name.refreshTaskCount, object: nil)
                                }
                            }
                        )
                    }
                }
            }
            .background(Color.white)
            .navigationTitle("My Tasks")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                },
                trailing: Button(action: {
                    Task {
                        await viewModel.refreshTasks()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                }
                .disabled(viewModel.isLoading)
            )
        }
        .sheet(isPresented: $showingTaskEdit) {
            if let task = selectedTask {
                NotificationCenterTaskEditView(
                    task: task.task,
                    onTaskUpdated: {
                        Task {
                            await viewModel.refreshTasks()
                        }
                    }
                )
            }
        }
        .onAppear {
            Task {
                await viewModel.loadTasks()
            }
        }
    }
}

// MARK: - Task List Header View

struct NotificationCenterHeaderView: View {
    @Binding var selectedFilter: TaskFilter
    @ObservedObject var viewModel: NotificationCenterViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            // Filter tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        FilterTabButton(
                            filter: filter,
                            isSelected: selectedFilter == filter,
                            viewModel: viewModel,
                            action: {
                                selectedFilter = filter
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
    }
}

// MARK: - Filter Tab Button

struct FilterTabButton: View {
    let filter: TaskFilter
    let isSelected: Bool
    @ObservedObject var viewModel: NotificationCenterViewModel
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)
                
                Text(filter == .completed ? filter.rawValue : "\(filter.rawValue) (\(getCount()))")
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? filter.color.opacity(0.2) : Color(.systemGray6))
            )
            .foregroundColor(isSelected ? filter.color : .primary)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? filter.color : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func getCount() -> Int {
        switch filter {
        case .todo:
            return viewModel.todoCount
        case .inProgress:
            return viewModel.inProgressCount
        case .completed:
            return 0
        }
    }
}

// MARK: - Loading View

struct NotificationCenterLoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading your tasks...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty State View

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 48))
                .foregroundColor(.green)
            
            Text("No Tasks Assigned")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You don't have any tasks assigned to you across your parties. Tasks will appear here when someone assigns them to you.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Empty Filter State View

struct EmptyFilterStateView: View {
    let filter: TaskFilter
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: filter.icon)
                .font(.system(size: 48))
                .foregroundColor(filter.color)
            
            Text("No \(filter.rawValue) Tasks")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("You don't have any \(filter.rawValue.lowercased()) tasks at the moment.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Task Edit View

struct NotificationCenterTaskEditView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var selectedStatus: TaskStatus
    @State private var selectedDueDate: Date?
    @State private var showingDatePicker = false
    
    let task: TaskModel
    let onTaskUpdated: () -> Void
    
    init(task: TaskModel, onTaskUpdated: @escaping () -> Void) {
        self.task = task
        self.onTaskUpdated = onTaskUpdated
        
        // Initialize state with task values
        self._title = State(initialValue: task.title)
        self._description = State(initialValue: task.description ?? "")
        self._selectedStatus = State(initialValue: task.status)
        self._selectedDueDate = State(initialValue: task.dueDate)
    }
    
    var body: some View {
        NavigationView {
            Form {
                // Title Section
                Section("Task Details") {
                    TextField("Task title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                // Status Section
                Section("Status") {
                    Picker("Status", selection: $selectedStatus) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
                
                // Due Date Section
                Section("Due Date") {
                    HStack {
                        Text("Due Date")
                        Spacer()
                        Button(action: {
                            showingDatePicker = true
                        }) {
                            if let dueDate = selectedDueDate {
                                Text(dueDate, style: .date)
                                    .foregroundColor(.primary)
                            } else {
                                Text("Set due date")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    
                    if selectedDueDate != nil {
                        Button("Clear due date") {
                            selectedDueDate = nil
                        }
                        .foregroundColor(.red)
                    }
                }
                
                // Task Info Section
                Section("Task Information") {
                    HStack {
                        Text("Created")
                        Spacer()
                        Text(DateOnlyFormatter.displayString(from: task.createdAt))
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Last Updated")
                        Spacer()
                        Text(DateOnlyFormatter.displayString(from: task.updatedAt))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTask()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePicker(
                "Select Due Date",
                selection: Binding(
                    get: { selectedDueDate ?? Date() },
                    set: { selectedDueDate = $0 }
                ),
                displayedComponents: .date
            )
            .datePickerStyle(WheelDatePickerStyle())
            .presentationDetents([.height(300)])
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingDatePicker = false
                    }
                }
            }
        }
    }
    
    private func saveTask() {
        let taskPatch = TaskModelPatch(
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            assignedTo: task.assignedTo, // Keep current assignee
            status: selectedStatus,
            dueDate: selectedDueDate
        )
        
        // Update the task using the service
        Task {
            do {
                let service = NotificationCenterService()
                try await service.updateTaskStatus(task.id, status: selectedStatus)
                onTaskUpdated()
                // Post notification to refresh dashboard count
                NotificationCenter.default.post(name: Notification.Name.refreshTaskCount, object: nil)
                dismiss()
            } catch {
                print("❌ Error updating task: \(error)")
            }
        }
    }
}

#Preview {
    NotificationCenterView()
}

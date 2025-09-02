import SwiftUI

struct TaskDetailView: View {
    let task: TaskModel
    let userRole: UserRole
    let onTaskUpdated: (TaskModel) -> Void
    let onTaskDeleted: (UUID) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedDescription: String
    @State private var editedStatus: TaskStatus
    @State private var editedDueDate: Date
    @State private var hasDueDate: Bool
    @State private var isSubmitting = false
    @State private var showingDeleteAlert = false
    @State private var errorMessage: String?
    
    init(task: TaskModel, userRole: UserRole, onTaskUpdated: @escaping (TaskModel) -> Void, onTaskDeleted: @escaping (UUID) -> Void) {
        self.task = task
        self.userRole = userRole
        self.onTaskUpdated = onTaskUpdated
        self.onTaskDeleted = onTaskDeleted
        
        // Initialize state with current task values
        self._editedTitle = State(initialValue: task.title)
        self._editedDescription = State(initialValue: task.description ?? "")
        self._editedStatus = State(initialValue: task.status)
        self._editedDueDate = State(initialValue: task.dueDate ?? Date())
        self._hasDueDate = State(initialValue: task.dueDate != nil)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    if isEditing {
                        TextField("Task title", text: $editedTitle)
                        
                        TextField("Description", text: $editedDescription, axis: .vertical)
                            .lineLimit(3...6)
                    } else {
                        HStack {
                            Text("Title")
                            Spacer()
                            Text(task.title)
                                .foregroundColor(.secondary)
                        }
                        
                        if let description = task.description, !description.isEmpty {
                            HStack {
                                Text("Description")
                                Spacer()
                                Text(description)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                }
                
                Section("Status") {
                    if isEditing {
                        Picker("Status", selection: $editedStatus) {
                            ForEach(TaskStatus.allCases, id: \.self) { status in
                                Text(status.displayName).tag(status)
                            }
                        }
                        .pickerStyle(.segmented)
                    } else {
                        HStack {
                            Text("Status")
                            Spacer()
                            Text(task.status.displayName)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(statusColor.opacity(0.1))
                                .foregroundColor(statusColor)
                                .cornerRadius(8)
                        }
                    }
                }
                
                Section("Due Date") {
                    if isEditing {
                        Toggle("Set due date", isOn: $hasDueDate)
                        
                        if hasDueDate {
                            DatePicker(
                                "Due date",
                                selection: $editedDueDate,
                                displayedComponents: .date
                            )
                        }
                    } else {
                        HStack {
                            Text("Due Date")
                            Spacer()
                            if let dueDate = task.dueDate {
                                Text(dueDate, style: .date)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("No due date")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Section("Assignment") {
                    HStack {
                        Text("Assigned to")
                        Spacer()
                        if let assignedToName = task.assignedToName, !assignedToName.isEmpty {
                            Text(assignedToName)
                                .foregroundColor(.secondary)
                        } else if task.assignedTo != nil {
                            Text("Unknown User")
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unassigned")
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    HStack {
                        Text("Created by")
                        Spacer()
                        if let createdByName = task.createdByName, !createdByName.isEmpty {
                            Text(createdByName)
                                .foregroundColor(.secondary)
                        } else {
                            Text("Unknown User")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                if isEditing {
                    Section {
                        Button("Save Changes") {
                            saveChanges()
                        }
                        .disabled(editedTitle.isEmpty || isSubmitting)
                        
                        Button("Cancel") {
                            cancelEditing()
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                if userRole == .admin || userRole == .organizer {
                    Section {
                        Button("Delete Task") {
                            showingDeleteAlert = true
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Done") {
                    dismiss()
                },
                trailing: (userRole == .admin || userRole == .organizer) ? Button(isEditing ? "Done" : "Edit") {
                    if isEditing {
                        saveChanges()
                    } else {
                        isEditing = true
                    }
                } : nil
            )
            .alert("Delete Task", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            }
            .alert("Error", isPresented: .constant(errorMessage != nil)) {
                Button("OK") {
                    errorMessage = nil
                }
            } message: {
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                }
            }
        }
    }
    
    private func saveChanges() {
        guard !editedTitle.isEmpty else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        let updatedTask = TaskModel(
            id: task.id,
            partyId: task.partyId,
            title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: editedDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            assignedTo: task.assignedTo,
            status: editedStatus,
            dueDate: hasDueDate ? editedDueDate : nil,
            completed: editedStatus == .completed,
            createdBy: task.createdBy,
            createdAt: task.createdAt,
            updatedAt: Date()
        )
        
        onTaskUpdated(updatedTask)
        isEditing = false
        isSubmitting = false
    }
    
    private func cancelEditing() {
        // Reset to original values
        editedTitle = task.title
        editedDescription = task.description ?? ""
        editedStatus = task.status
        editedDueDate = task.dueDate ?? Date()
        hasDueDate = task.dueDate != nil
        isEditing = false
    }
    
    private func deleteTask() {
        onTaskDeleted(task.id)
        dismiss()
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

#Preview {
    TaskDetailView(
        task: TaskModel(
            id: UUID(),
            partyId: UUID(),
            title: "Sample Task",
            description: "This is a sample task description",
            assignedTo: nil,
            status: .todo,
            dueDate: Date().addingTimeInterval(86400),
            completed: false,
            createdBy: UUID(),
            createdAt: Date(),
            updatedAt: Date()
        ),
        userRole: .organizer,
        onTaskUpdated: { _ in },
        onTaskDeleted: { _ in }
    )
}

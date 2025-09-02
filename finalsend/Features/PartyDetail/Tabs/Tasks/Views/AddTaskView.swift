import SwiftUI

struct AddTaskView: View {
    let partyId: UUID
    let currentUserId: UUID
    let onTaskAdded: (TaskModel) -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var assignedTo: UUID? = nil
    @State private var status: TaskStatus = .todo
    @State private var dueDate: Date = Date()
    @State private var hasDueDate = false
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Assignment") {
                    Picker("Status", selection: $status) {
                        ForEach(TaskStatus.allCases, id: \.self) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    // For now, we'll keep assignedTo as nil (unassigned)
                    // This can be enhanced later to show party attendees
                    Text("Assigned to: Unassigned")
                        .foregroundColor(.secondary)
                }
                
                Section("Due Date") {
                    Toggle("Set due date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker(
                            "Due date",
                            selection: $dueDate,
                            displayedComponents: .date
                        )
                    }
                }
            }
            .navigationTitle("Add Task")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    saveTask()
                }
                .disabled(title.isEmpty || isSubmitting)
            )
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
    
    private func saveTask() {
        guard !title.isEmpty else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        let task = TaskModel(
            id: UUID(),
            partyId: partyId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            description: description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines),
            assignedTo: assignedTo,
            status: status,
            dueDate: hasDueDate ? dueDate : nil,
            completed: false,
            createdBy: currentUserId,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        onTaskAdded(task)
        dismiss()
    }
}

#Preview {
    AddTaskView(
        partyId: UUID(),
        currentUserId: UUID(),
        onTaskAdded: { _ in }
    )
}

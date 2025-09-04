import SwiftUI

struct AddExpenseView: View {
    let partyId: String
    let currentUserId: String
    let attendees: [PartyAttendee]
    let onDismiss: () -> Void
    let onExpenseCreated: () -> Void
    
    @ObservedObject var expensesStore: ExpensesStore
    @State private var formData = ExpenseFormData()
    @State private var isSubmitting = false
    @State private var showValidationErrors = false
    @State private var showPaidByPicker = false
    @State private var showCategoryPicker = false
    
    init(partyId: String, currentUserId: String, attendees: [PartyAttendee], expensesStore: ExpensesStore, onDismiss: @escaping () -> Void, onExpenseCreated: @escaping () -> Void) {
        self.partyId = partyId
        self.currentUserId = currentUserId
        self.attendees = attendees
        self.expensesStore = expensesStore
        self.onDismiss = onDismiss
        self.onExpenseCreated = onExpenseCreated
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Title Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Title")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("Enter expense title", text: $formData.title)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    }
                    
                    // Amount Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        HStack(spacing: 12) {
                            // Currency Picker
                            Button(action: {
                                // TODO: Add currency picker functionality
                            }) {
                                HStack(spacing: 4) {
                                    Text("$")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.primary)
                                    
                                    Image(systemName: "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Number Input Field
                            TextField("0.00", value: Binding(
                                get: { formData.amount },
                                set: { formData.amount = $0 }
                            ), format: .number)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                        }
                    }
                    
                    // Paid By Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paid By")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showPaidByPicker.toggle()
                                }
                            }) {
                                HStack {
                                    Text(attendees.first(where: { $0.userId == formData.paidBy })?.fullName ?? "Select who paid")
                                        .font(.system(size: 16))
                                        .foregroundColor(formData.paidBy.isEmpty ? .secondary : .primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: showPaidByPicker ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Dropdown Menu
                            if showPaidByPicker {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(attendees, id: \.userId) { attendee in
                                            Button(action: {
                                                formData.paidBy = attendee.userId
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showPaidByPicker = false
                                                }
                                            }) {
                                                HStack {
                                                    Text(attendee.fullName)
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                    
                                                    if formData.paidBy == attendee.userId {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 16, weight: .medium))
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color(.systemGray5))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .frame(maxHeight: 200) // Limit height to ~4-5 items
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Category Picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        VStack(spacing: 0) {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    showCategoryPicker.toggle()
                                }
                            }) {
                                HStack {
                                    Text(formData.category.displayName)
                                        .font(.system(size: 16))
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Image(systemName: showCategoryPicker ? "chevron.up" : "chevron.down")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                            
                            // Dropdown Menu
                            if showCategoryPicker {
                                ScrollView {
                                    VStack(spacing: 0) {
                                        ForEach(ExpenseCategory.allCases.filter { $0 != .settlement }, id: \.self) { category in
                                            Button(action: {
                                                formData.category = category
                                                withAnimation(.easeInOut(duration: 0.2)) {
                                                    showCategoryPicker = false
                                                }
                                            }) {
                                                HStack {
                                                    Text(category.displayName)
                                                        .font(.system(size: 16))
                                                        .foregroundColor(.primary)
                                                    
                                                    Spacer()
                                                    
                                                    if formData.category == category {
                                                        Image(systemName: "checkmark")
                                                            .font(.system(size: 16, weight: .medium))
                                                            .foregroundColor(.blue)
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                                .padding(.vertical, 12)
                                                .background(Color(.systemGray5))
                                            }
                                            .buttonStyle(PlainButtonStyle())
                                        }
                                    }
                                }
                                .frame(maxHeight: 200) // Limit height to ~4-5 items
                                .background(Color(.systemGray5))
                                .cornerRadius(12)
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Notes Field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Notes")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                        
                        TextField("Add notes...", text: $formData.notes, axis: .vertical)
                            .font(.system(size: 16))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            .lineLimit(3...6)
                    }
                    
                    // Split Management Section
                    ExpenseSplitView(
                        formData: $formData,
                        attendees: attendees
                    )
                    
                    // Validation Errors
                    if showValidationErrors && !formData.validationErrors.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(formData.validationErrors, id: \.self) { error in
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.red)
                                    Text(error)
                                        .font(.system(size: 14))
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        .padding(16)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    
                    Spacer(minLength: 100)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                },
                trailing: Button("Add") {
                    submitExpense()
                }
                .disabled(isSubmitting || !formData.isValid)
            )
        }
        .onAppear {
            // Set default paid by to current user if available
            if formData.paidBy.isEmpty && !attendees.isEmpty {
                if let currentUser = attendees.first(where: { $0.userId.uppercased() == currentUserId.uppercased() }) {
                    formData.paidBy = currentUser.userId
                } else {
                    formData.paidBy = attendees[0].userId
                }
            }
            
            // Set default selected users to all attendees
            if formData.selectedUsers.isEmpty {
                formData.selectedUsers = Set(attendees.map { $0.userId })
            }
        }
    }
    
    private func submitExpense() {
        showValidationErrors = true
        
        guard formData.isValid else {
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                try await expensesStore.createExpense(
                    formData: formData,
                    partyId: UUID(uuidString: partyId) ?? UUID(),
                    currentUserId: UUID(uuidString: currentUserId) ?? UUID()
                )
                
                await MainActor.run {
                    isSubmitting = false
                    onExpenseCreated()
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // TODO: Show error alert
                    print("Error creating expense: \(error)")
                }
            }
        }
    }
}

#Preview {
    AddExpenseView(
        partyId: "test-party",
        currentUserId: "test-user",
        attendees: [
            PartyAttendee(fullName: "John Doe"),
            PartyAttendee(fullName: "Jane Smith")
        ],
        expensesStore: ExpensesStore(supabase: SupabaseManager.shared.client),
        onDismiss: {},
        onExpenseCreated: {}
    )
}

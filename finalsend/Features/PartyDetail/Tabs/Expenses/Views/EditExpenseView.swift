import SwiftUI
import Supabase

struct EditExpenseView: View {
    let expense: Expense
    let partyId: String
    let currentUserId: String
    let attendees: [PartyAttendee]
    let onDismiss: () -> Void
    let onExpenseUpdated: () -> Void
    
    @ObservedObject var expensesStore: ExpensesStore
    @State private var formData = ExpenseFormData()
    @State private var isSubmitting = false
    @State private var showValidationErrors = false
    @State private var showPaidByPicker = false
    @State private var showCategoryPicker = false
    
    init(expense: Expense, partyId: String, currentUserId: String, attendees: [PartyAttendee], expensesStore: ExpensesStore, onDismiss: @escaping () -> Void, onExpenseUpdated: @escaping () -> Void) {
        self.expense = expense
        self.partyId = partyId
        self.currentUserId = currentUserId
        self.attendees = attendees
        self.expensesStore = expensesStore
        self.onDismiss = onDismiss
        self.onExpenseUpdated = onExpenseUpdated
    }
    
    var body: some View {
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
                    
                    if showValidationErrors && formData.title.isEmpty {
                        Text("Title is required")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
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
                    
                    if showValidationErrors && (formData.amount ?? 0) <= 0 {
                        Text("Amount must be greater than 0")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
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
                    
                    if showValidationErrors && formData.paidBy.isEmpty {
                        Text("Please select who paid")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
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
                                    .font(.system(size: 14))
                                
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(.red)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer(minLength: 100)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .navigationTitle("Edit Expense")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Update") {
                    updateExpense()
                }
                .disabled(isSubmitting || !formData.isValid)
            }
        }
        .onAppear {
            // Prefill form with existing expense data
            formData.title = expense.title
            formData.amount = expense.amount
            formData.paidBy = expense.paidBy.uuidString.lowercased()
            formData.category = ExpenseCategory(rawValue: expense.category) ?? .general
            formData.notes = expense.notes ?? ""
            
            // Set split type - default to even for now to avoid computation
            formData.splitType = .even
            
            // Set selected users from existing splits
            if !expense.splits.isEmpty {
                let splitUserIds = expense.splits.map { $0.userId.uuidString.lowercased() }
                formData.selectedUsers = Set(splitUserIds)
            } else {
                let allUserIds = attendees.map { $0.userId }
                formData.selectedUsers = Set(allUserIds)
            }
        }
    }
    
    private var paidByDisplayName: String {
        if let attendee = attendees.first(where: { $0.userId == formData.paidBy }) {
            return attendee.fullName
        }
        return "Select who paid"
    }
    
    private func updateExpense() {
        showValidationErrors = true
        
        guard formData.isValid else {
            return
        }
        
        isSubmitting = true
        
        Task {
            do {
                try await expensesStore.updateExpense(
                    expenseId: expense.id,
                    formData: formData,
                    partyId: UUID(uuidString: partyId) ?? UUID(),
                    currentUserId: UUID(uuidString: currentUserId) ?? UUID()
                )
                
                await MainActor.run {
                    isSubmitting = false
                    onExpenseUpdated()
                    onDismiss()
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    // TODO: Show error alert
                    print("Error updating expense: \(error)")
                }
            }
        }
    }
}

#Preview {
    let sampleExpenseResponse = ExpenseResponse(
        id: UUID(uuidString: "15A35BAD-D70B-4BAE-9B33-7B1D1C09D16C")!,
        party_id: UUID(uuidString: "party-123")!,
        title: "Dinner at Restaurant",
        amount: 85.50,
        paid_by: UUID(uuidString: "15a35bad-d70b-4bae-9b33-7b1d1c09d16c")!,
        received_by: nil,
        date: "2024-01-15T19:30:00Z",
        category: "food",
        split_type: "even",
        notes: "Great meal with the team",
        receipt_image_url: nil,
        created_at: "2024-01-15T19:30:00Z",
        created_by: UUID(uuidString: "user-123"),
        updated_at: "2024-01-15T19:30:00Z",
        expense_splits: []
    )
    
    let sampleExpense = try! Expense(from: sampleExpenseResponse)
    
    EditExpenseView(
        expense: sampleExpense,
        partyId: "party-123",
        currentUserId: "user-123",
        attendees: [],
        expensesStore: ExpensesStore(supabase: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: "example-key")),
        onDismiss: {},
        onExpenseUpdated: {}
    )
}

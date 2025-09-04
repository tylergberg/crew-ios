import SwiftUI

struct ExpenseDetailView: View {
    let expense: Expense
    @ObservedObject var expensesStore: ExpensesStore
    let currentUserId: String
    let partyId: String
    let onDismiss: () -> Void
    
    @State private var showEditExpense = false
    @State private var showDeleteAlert = false
    @State private var isLoading = true
    
    private var paidByName: String {
        let name = expensesStore.getAttendeeName(by: expense.paidBy.uuidString)
        return name.isEmpty ? "Unknown User" : name
    }
    
    private var categoryDisplayName: String {
        switch expense.category {
        case "food":
            return "Food"
        case "transportation":
            return "Transportation"
        case "lodging":
            return "Lodging"
        case "alcohol":
            return "Alcohol"
        case "activity":
            return "Activity"
        case "settlement":
            return "Settlement"
        default:
            return "General"
        }
    }
    
    private var splitTypeDisplay: String {
        switch expense.splitType {
        case "even":
            return "Even Split"
        case "custom":
            return "Custom Split"
        case "percentage":
            return "Percentage Split"
        default:
            return "Split"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: expense.date)
    }
    
    private var formattedAmount: String {
        return String(format: "$%.2f", expense.amount)
    }
    
    init(expense: Expense, expensesStore: ExpensesStore, currentUserId: String, partyId: String, onDismiss: @escaping () -> Void) {
        self.expense = expense
        self.expensesStore = expensesStore
        self.currentUserId = currentUserId
        self.partyId = partyId
        self.onDismiss = onDismiss
        print("🔍 ExpenseDetailView: Initialized with expense '\(expense.title)', attendees count: \(expensesStore.attendees.count)")
    }
    
    var body: some View {
        Group {
                if isLoading || expensesStore.attendees.isEmpty {
                    VStack {
                        Spacer()
                        ProgressView("Loading...")
                            .font(.system(size: 16))
                        Spacer()
                    }
                    .onAppear {
                        print("🔍 ExpenseDetailView: Loading state onAppear - attendees count: \(expensesStore.attendees.count), isLoading: \(isLoading)")
                        // Ensure attendees are loaded
                        Task {
                            await expensesStore.loadAllWithAttendees(
                                partyId: UUID(uuidString: partyId) ?? UUID(),
                                userId: UUID(uuidString: currentUserId) ?? UUID()
                            )
                            print("🔍 ExpenseDetailView: After loadAllWithAttendees - attendees count: \(expensesStore.attendees.count)")
                            // Mark loading as complete
                            DispatchQueue.main.async {
                                isLoading = false
                                print("🔍 ExpenseDetailView: Set isLoading to false")
                            }
                        }
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 16) {
                            // Header Card
                            VStack(spacing: 16) {
                                // Title and Amount
                                VStack(spacing: 8) {
                                    Text(expense.title)
                                        .font(.system(size: 20, weight: .bold))
                                        .foregroundColor(.primary)
                                        .multilineTextAlignment(.center)
                                    
                                    Text(formattedAmount)
                                        .font(.system(size: 28, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                                
                                Divider()
                                
                                // Details Grid
                                VStack(spacing: 12) {
                                    DetailRow(label: "Paid By", value: paidByName)
                                    DetailRow(label: "Date", value: formattedDate)
                                    DetailRow(label: "Category", value: categoryDisplayName)
                                    DetailRow(label: "Split Type", value: splitTypeDisplay)
                                }
                                
                                if let notes = expense.notes, !notes.isEmpty {
                                    Divider()
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Notes")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.primary)
                                        
                                        Text(notes)
                                            .font(.system(size: 16))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.leading)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                            
                            // Split Breakdown
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Split Breakdown")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.primary)
                                
                                VStack(spacing: 8) {
                                    ForEach(expense.splits, id: \.id) { split in
                                        SplitRowView(
                                            split: split,
                                            expensesStore: expensesStore,
                                            isCurrentUser: split.userId.uuidString.uppercased() == currentUserId.uppercased()
                                        )
                                    }
                                }
                            }
                            .padding(16)
                            .background(Color.white)
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        }
                        .padding(16)
                        .background(Color(.systemGroupedBackground))
                        .onAppear {
                            print("🔍 ExpenseDetailView: Main content onAppear - attendees count: \(expensesStore.attendees.count), isLoading: \(isLoading)")
                            // Ensure we're not in loading state when content appears
                            isLoading = false
                        }
                    }
                }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing: Menu {
                Button("Edit Expense") {
                    showEditExpense = true
                }
                
                Button("Delete Expense", role: .destructive) {
                    showDeleteAlert = true
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 20))
            }
        )
        .sheet(isPresented: $showEditExpense) {
            // TODO: Implement EditExpenseView
            Text("Edit Expense - Coming Soon")
        }
        .alert("Delete Expense", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                // TODO: Implement delete functionality
            }
        } message: {
            Text("Are you sure you want to delete this expense? This action cannot be undone.")
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

struct SplitRowView: View {
    let split: ExpenseSplit
    @ObservedObject var expensesStore: ExpensesStore
    let isCurrentUser: Bool
    
    private var userName: String {
        let name = expensesStore.getAttendeeName(by: split.userId.uuidString)
        return name.isEmpty ? "Unknown User" : name
    }
    
    private var owedAmount: String {
        if let owed = split.owedShare {
            return String(format: "$%.2f", owed)
        }
        return "$0.00"
    }
    
    private var paidAmount: String {
        if let paid = split.paidShare {
            return String(format: "$%.2f", paid)
        }
        return "$0.00"
    }
    
    private var netAmount: Double {
        let paid = split.paidShare ?? 0
        let owed = split.owedShare ?? 0
        return paid - owed
    }
    
    private var netAmountString: String {
        let amount = netAmount
        return String(format: "$%.2f", abs(amount))
    }
    
    private var netAmountColor: Color {
        if netAmount > 0 {
            return .green
        } else if netAmount < 0 {
            return .red
        } else {
            return .secondary
        }
    }
    
    private var netAmountPrefix: String {
        if netAmount > 0 {
            return "owes you"
        } else if netAmount < 0 {
            return "you owe"
        } else {
            return "settled"
        }
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(userName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isCurrentUser ? .blue : .primary)
                
                if isCurrentUser {
                    Text("(You)")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(owedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(isCurrentUser ? .blue : .primary)
                
                Text("owed")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(isCurrentUser ? Color.blue.opacity(0.1) : Color.gray.opacity(0.05))
        .cornerRadius(8)
    }
}

#Preview {
    Text("Expense Detail Preview")
        .font(.title)
}

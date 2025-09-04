import SwiftUI

enum ExpensesTab: String, CaseIterable {
    case expenses = "Expenses"
    case balances = "Balances"
    case settle = "Settle"
}

struct ExpensesTabView: View {
    let partyId: String
    let currentUserId: String
    let attendeesCount: Int
    let attendees: [PartyAttendee]
    let onDismiss: () -> Void
    
    @State private var selectedTab: ExpensesTab = .expenses
    @StateObject private var expensesStore: ExpensesStore
    @State private var showAddExpense = false
    @State private var selectedExpense: Expense? = nil
    
    init(partyId: String, currentUserId: String, attendeesCount: Int, attendees: [PartyAttendee] = [], onDismiss: @escaping () -> Void) {
        self.partyId = partyId
        self.currentUserId = currentUserId
        self.attendeesCount = attendeesCount
        self.attendees = attendees
        self.onDismiss = onDismiss
        self._expensesStore = StateObject(wrappedValue: ExpensesStore(supabase: SupabaseManager.shared.client))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Expenses Tab", selection: $selectedTab) {
                    ForEach(ExpensesTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    ExpensesListView(
                        expensesStore: expensesStore, 
                        showAddExpense: $showAddExpense,
                        onExpenseSelected: { expense in
                            print("🔍 ExpensesTabView: Expense selected - '\(expense.title)', amount: $\(expense.amount)")
                            selectedExpense = expense
                        }
                    )
                    .tag(ExpensesTab.expenses)
                    
                    BalancesListView(
                        expensesStore: expensesStore,
                        currentUserId: currentUserId
                    )
                        .tag(ExpensesTab.balances)
                    
                    SettleListView(
                        expensesStore: expensesStore,
                        currentUserId: currentUserId
                    )
                        .tag(ExpensesTab.settle)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Expenses")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Back") {
                    onDismiss()
                }
            )
            .onAppear {
                // Update attendees in the store
                expensesStore.updateAttendees(attendees)
                
                Task {
                    await expensesStore.loadAllWithAttendees(
                        partyId: UUID(uuidString: partyId) ?? UUID(),
                        userId: UUID(uuidString: currentUserId) ?? UUID()
                    )
                }
            }
            .sheet(isPresented: $showAddExpense) {
                AddExpenseView(
                    partyId: partyId,
                    currentUserId: currentUserId,
                    attendees: attendees,
                    expensesStore: expensesStore,
                    onDismiss: {
                        showAddExpense = false
                    },
                    onExpenseCreated: {
                        // Expense was created successfully
                        showAddExpense = false
                    }
                )
            }
            .background(
                NavigationLink(
                    destination: Group {
                        if let expense = selectedExpense {
                            ExpenseDetailView(
                                expenseId: expense.id.uuidString,
                                expensesStore: expensesStore,
                                currentUserId: currentUserId,
                                partyId: partyId,
                                onDismiss: {
                                    print("🔍 ExpensesTabView: ExpenseDetailView dismissed")
                                    selectedExpense = nil
                                }
                            )
                        }
                    },
                    isActive: Binding(
                        get: { selectedExpense != nil },
                        set: { if !$0 { selectedExpense = nil } }
                    )
                ) {
                    EmptyView()
                }
            )
        }
    }
}

// MARK: - Tab Content Views

struct ExpensesListView: View {
    @ObservedObject var expensesStore: ExpensesStore
    @Binding var showAddExpense: Bool
    let onExpenseSelected: (Expense) -> Void
    
    // Group expenses by date
    private var groupedExpenses: [ExpenseDateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: expensesStore.expenses) { expense in
            calendar.startOfDay(for: expense.date)
        }
        
        return grouped.map { date, expenses in
            ExpenseDateGroup(date: date, expenses: expenses.sorted { $0.date > $1.date })
        }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ZStack {
            // Expense List
            if expensesStore.isLoading {
                VStack {
                    Spacer()
                    ProgressView("Loading expenses...")
                        .font(.system(size: 16))
                    Spacer()
                }
            } else if expensesStore.expenses.isEmpty {
                VStack {
                    Spacer()
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.gray)
                    Text("No expenses yet")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top, 16)
                    Text("Start adding expenses to track and split costs with your crew.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedExpenses, id: \.date) { dateGroup in
                            VStack(spacing: 0) {
                                // Date Header
                                HStack {
                                    Text(dateGroup.dateString)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Spacer()
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                
                                // Expenses for this date
                                VStack(spacing: 12) {
                                    ForEach(dateGroup.expenses) { expense in
                                        Button(action: {
                                            onExpenseSelected(expense)
                                        }) {
                                            ExpenseCardView(expense: expense, expensesStore: expensesStore)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 16)
                            }
                        }
                    }
                    .padding(.bottom, 100) // Add bottom padding to prevent overlap with FAB
                }
            }
            
            // Floating Add Expense Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: {
                        showAddExpense = true
                    }) {
                        Image(systemName: "plus")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                    }
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
    }
}

struct BalancesListView: View {
    @ObservedObject var expensesStore: ExpensesStore
    let currentUserId: String
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Your Balance Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Your Balance")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let userBalance = expensesStore.balances.first(where: { $0.key.uppercased() == currentUserId.uppercased() })?.value {
                        VStack(spacing: 12) {
                            BalanceRowView(
                                title: "Total Paid",
                                amount: userBalance.totalPaid,
                                color: .primary
                            )
                            
                            BalanceRowView(
                                title: "Total Share",
                                amount: userBalance.totalOwed,
                                color: .primary
                            )
                            
                            Divider()
                            
                            BalanceRowView(
                                title: "Net Balance",
                                amount: userBalance.net,
                                color: userBalance.net >= 0 ? .green : .red,
                                isBold: true
                            )
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .onAppear {
                            print("💰 [BalancesListView] Found user balance for \(currentUserId): paid=\(userBalance.totalPaid), owed=\(userBalance.totalOwed), net=\(userBalance.net)")
                        }
                    } else {
                        Text("No balance data available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .onAppear {
                                print("💰 [BalancesListView] No balance found for currentUserId: \(currentUserId)")
                                print("💰 [BalancesListView] Available user IDs in balances: \(expensesStore.balances.keys.map { $0.uppercased() })")
                            }
                    }
                }
                
                // All Balances Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("All Balances")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if expensesStore.balances.isEmpty {
                        Text("No balance data available")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 8) {
                            ForEach(Array(expensesStore.balances.keys.sorted { 
                                let balance1 = expensesStore.balances[$0]?.net ?? 0
                                let balance2 = expensesStore.balances[$1]?.net ?? 0
                                return balance1 > balance2 // Sort by net balance descending (highest to lowest)
                            }), id: \.self) { userId in
                                if let balance = expensesStore.balances[userId] {
                                    AllBalanceRowView(
                                        userId: userId,
                                        balance: balance,
                                        isCurrentUser: userId.uppercased() == currentUserId.uppercased(),
                                        expensesStore: expensesStore
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
                
                
                Spacer(minLength: 100) // Bottom padding for FAB
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

struct SettleListView: View {
    @ObservedObject var expensesStore: ExpensesStore
    let currentUserId: String
    @State private var showSettlementConfirmation = false
    
    // Calculate settlement suggestions (who pays whom)
    private var settlementSuggestions: [SettlementSuggestion] {
        var suggestions: [SettlementSuggestion] = []
        let balances = expensesStore.balances
        
        // Find debtors (negative balances) and creditors (positive balances)
        let debtors = balances.filter { $0.value.net < -0.01 }.sorted { $0.value.net < $1.value.net }
        let creditors = balances.filter { $0.value.net > 0.01 }.sorted { $0.value.net > $1.value.net }
        
        var remainingDebts = debtors.map { ($0.key, abs($0.value.net)) }
        var remainingCredits = creditors.map { ($0.key, $0.value.net) }
        
        // Optimize settlements to minimize number of transactions
        while !remainingDebts.isEmpty && !remainingCredits.isEmpty {
            let (debtorId, debtAmount) = remainingDebts[0]
            let (creditorId, creditAmount) = remainingCredits[0]
            
            let settlementAmount = min(debtAmount, creditAmount)
            
            suggestions.append(SettlementSuggestion(
                from: debtorId,
                to: creditorId,
                amount: settlementAmount
            ))
            
            // Update remaining amounts
            if debtAmount - settlementAmount < 0.01 {
                remainingDebts.removeFirst()
            } else {
                remainingDebts[0] = (debtorId, debtAmount - settlementAmount)
            }
            
            if creditAmount - settlementAmount < 0.01 {
                remainingCredits.removeFirst()
            } else {
                remainingCredits[0] = (creditorId, creditAmount - settlementAmount)
            }
        }
        
        return suggestions
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Settlement Toggle Card
                VStack(spacing: 12) {
                    // Toggle (only show when not in settlement mode)
                    if !expensesStore.isSettlementMode {
                        HStack {
                            Text("Ready to settle up?")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Toggle("", isOn: Binding(
                                get: { expensesStore.isSettlementMode },
                                set: { _ in showSettlementConfirmation = true }
                            ))
                            .toggleStyle(SwitchToggleStyle(tint: .orange))
                        }
                        
                        // Warning message
                        Text("⚠️ Once enabled, expenses will be locked and payments can begin")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.orange)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        // Settlement mode active
                        HStack {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.orange)
                            
                            Text("Settlement Mode Active")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                        }
                        
                        Text("Expenses are locked. Use the payment suggestions below to settle up.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(16)
                .background(expensesStore.isSettlementMode ? Color.orange.opacity(0.1) : Color.blue.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(expensesStore.isSettlementMode ? Color.orange.opacity(0.3) : Color.blue.opacity(0.3), lineWidth: 1)
                )
                .alert("Enable Settlement Mode?", isPresented: $showSettlementConfirmation) {
                    Button("Cancel", role: .cancel) { }
                    Button("Lock Expenses", role: .destructive) {
                        expensesStore.toggleSettlementMode()
                    }
                } message: {
                    Text("This will lock all expenses and enable payment tracking. You won't be able to add or modify expenses after this.")
                }
                
                // Who Pays Whom Section
                VStack(alignment: .leading, spacing: 16) {
                    Text("Who Pays Whom")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if settlementSuggestions.isEmpty {
                        Text("Everyone is settled up! 🎉")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(16)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(settlementSuggestions, id: \.id) { suggestion in
                                SettlementRowView(
                                    suggestion: suggestion,
                                    expensesStore: expensesStore,
                                    isCurrentUserInvolved: currentUserId.uppercased() == suggestion.from.uppercased() || currentUserId.uppercased() == suggestion.to.uppercased()
                                )
                            }
                        }
                    }
                }
                
                Spacer(minLength: 100) // Bottom padding for FAB
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
    }
}

// MARK: - Expense Card View

struct ExpenseCardView: View {
    let expense: Expense
    @ObservedObject var expensesStore: ExpensesStore
    
    private var categoryIcon: String {
        switch expense.category {
        case "food":
            return "fork.knife"
        case "transportation":
            return "car"
        case "lodging":
            return "bed.double"
        case "alcohol":
            return "wineglass"
        case "activity":
            return "figure.walk"
        case "settlement":
            return "creditcard"
        default:
            return "dollarsign.circle"
        }
    }
    
    private var categoryColor: Color {
        switch expense.category {
        case "food":
            return Color.orange.opacity(0.7)
        case "transportation":
            return Color.blue.opacity(0.7)
        case "lodging":
            return Color.green.opacity(0.7)
        case "alcohol":
            return Color.purple.opacity(0.7)
        case "activity":
            return Color.blue.opacity(0.7)
        case "settlement":
            return Color.purple.opacity(0.7)
        default:
            return Color.gray.opacity(0.7)
        }
    }
    
    private var formattedAmount: String {
        return String(format: "$%.2f", expense.amount)
    }
    
    private var paidByName: String {
        return expensesStore.getAttendeeName(by: expense.paidBy.uuidString)
    }
    
    private var splitTypeDisplay: String {
        switch expense.splitType {
        case "even":
            return "Even split"
        case "custom":
            return "Custom split"
        case "percentage":
            return "Percentage split"
        default:
            return "Split"
        }
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(categoryColor)
                    .frame(width: 40, height: 40)
                
                Image(systemName: categoryIcon)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // Expense Details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Paid by: \(paidByName)")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text("\(splitTypeDisplay) with \(expense.splits.count) people")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Amount
            Text(formattedAmount)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.primary)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}


// MARK: - Date Grouping Models

struct ExpenseDateGroup {
    let date: Date
    let expenses: [Expense]
    
    var dateString: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(date) {
            return "Today"
        } else if calendar.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Balance Row Views

struct BalanceRowView: View {
    let title: String
    let amount: Double
    let color: Color
    let isBold: Bool
    
    init(title: String, amount: Double, color: Color, isBold: Bool = false) {
        self.title = title
        self.amount = amount
        self.color = color
        self.isBold = isBold
    }
    
    private var formattedAmount: String {
        return String(format: "$%.2f", amount)
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: isBold ? .bold : .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(formattedAmount)
                .font(.system(size: 16, weight: isBold ? .bold : .medium))
                .foregroundColor(color)
        }
    }
}

struct AllBalanceRowView: View {
    let userId: String
    let balance: ExpenseBalance
    let isCurrentUser: Bool
    let expensesStore: ExpensesStore
    
    private var formattedAmount: String {
        return String(format: "$%.2f", balance.net)
    }
    
    private var displayName: String {
        if isCurrentUser {
            return "You"
        } else {
            let name = expensesStore.getAttendeeName(by: userId)
            print("💰 [AllBalanceRowView] Getting name for userId: \(userId) -> \(name)")
            return name
        }
    }
    
    var body: some View {
        HStack {
            Text(displayName)
                .font(.system(size: 16, weight: isCurrentUser ? .bold : .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(formattedAmount)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(balance.net >= 0 ? .green : .red)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Settlement Models and Views

struct SettlementSuggestion: Identifiable {
    let id = UUID()
    let from: String
    let to: String
    let amount: Double
}

struct SettlementRowView: View {
    let suggestion: SettlementSuggestion
    let expensesStore: ExpensesStore
    let isCurrentUserInvolved: Bool
    
    private var formattedAmount: String {
        return String(format: "$%.2f", suggestion.amount)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // User A > User B
            HStack {
                Text(expensesStore.getAttendeeName(by: suggestion.from))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
                
                Text(expensesStore.getAttendeeName(by: suggestion.to))
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            // Amount
            HStack {
                Text(formattedAmount)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.primary)
                
                Spacer()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(isCurrentUserInvolved ? Color.blue.opacity(0.1) : Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentUserInvolved ? Color.blue.opacity(0.3) : Color(.systemGray5), lineWidth: 1)
        )
    }
}

#Preview {
    ExpensesTabView(
        partyId: "test-party",
        currentUserId: "test-user",
        attendeesCount: 5,
        attendees: [],
        onDismiss: {}
    )
}


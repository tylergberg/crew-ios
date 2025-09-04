import Foundation
import Supabase

@MainActor
class ExpensesStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var balances: [String: ExpenseBalance] = [:]
    @Published var isSettlementMode = false
    @Published var attendees: [PartyAttendee] = []
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func loadAllWithAttendees(partyId: UUID, userId: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            print("💰 [ExpensesStore] Fetching expenses for party \(partyId)")
            
            // Fetch expenses with their splits, following the web pattern
            let response: [ExpenseResponse] = try await supabase
                .from("expenses")
                .select("""
                    *,
                    expense_splits(*)
                """)
                .eq("party_id", value: partyId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Convert to Expense models
            let expenseModels = response.compactMap { expenseResponse -> Expense? in
                do {
                    return try Expense(from: expenseResponse)
                } catch {
                    print("💰 [ExpensesStore] Error converting expense \(expenseResponse.id): \(error)")
                    return nil
                }
            }
            
            self.expenses = expenseModels
            print("💰 [ExpensesStore] Successfully loaded \(expenseModels.count) expenses")
            
            // Fetch balances from database view instead of calculating client-side
            await loadBalancesFromDatabase(partyId: partyId)
            
        } catch {
            self.error = error
            print("💰 [ExpensesStore] Error loading expenses: \(error)")
        }
    }
    
    func cleanup() {
        expenses = []
        error = nil
        balances = [:]
    }
    
    // MARK: - Database Balance Loading
    
    private func loadBalancesFromDatabase(partyId: UUID) async {
        do {
            print("💰 [ExpensesStore] Fetching balances from user_expense_balances view for party \(partyId)")
            
            let response: [UserExpenseBalanceResponse] = try await supabase
                .from("user_expense_balances")
                .select("*")
                .eq("party_id", value: partyId)
                .order("net_balance", ascending: false)
                .execute()
                .value
            
            var userBalances: [String: ExpenseBalance] = [:]
            
            for balanceResponse in response {
                if let userId = balanceResponse.user_id {
                    userBalances[userId] = ExpenseBalance(
                        totalPaid: balanceResponse.total_paid ?? 0,
                        totalOwed: balanceResponse.total_owed ?? 0,
                        net: balanceResponse.net_balance ?? 0
                    )
                    
                    print("💰 [ExpensesStore] Balance for \(userId): paid=\(balanceResponse.total_paid ?? 0), owed=\(balanceResponse.total_owed ?? 0), net=\(balanceResponse.net_balance ?? 0)")
                }
            }
            
            self.balances = userBalances
            print("💰 [ExpensesStore] Successfully loaded \(userBalances.count) balances from database")
            
        } catch {
            print("💰 [ExpensesStore] Error loading balances from database: \(error)")
            // Fallback to client-side calculation if database view fails
            calculateBalances(for: attendees.first?.userId ?? "")
        }
    }
    
    // MARK: - Balance Calculations
    
    func calculateBalances(for userId: String) {
        print("💰 [ExpensesStore] Starting balance calculation...")
        print("💰 [ExpensesStore] Expenses count: \(expenses.count)")
        print("💰 [ExpensesStore] Attendees count: \(attendees.count)")
        
        var userBalances: [String: ExpenseBalance] = [:]
        
        if expenses.isEmpty {
            print("💰 [ExpensesStore] No expenses found, initializing empty balances for all attendees")
            // Initialize empty balances for all attendees
            for attendee in attendees {
                userBalances[attendee.userId] = ExpenseBalance(
                    totalPaid: 0,
                    totalOwed: 0,
                    net: 0
                )
            }
        } else {
            // Calculate balances for each user using the same logic as web app
            // Initialize balances for all attendees first
            for attendee in attendees {
                userBalances[attendee.userId] = ExpenseBalance(
                    totalPaid: 0,
                    totalOwed: 0,
                    net: 0
                )
            }
            
            // Process each expense and its splits
            for expense in expenses {
                if expense.category == "settlement" {
                    // Handle settlement expenses - these directly adjust net balances
                    if let paidBy = expense.paidBy.uuidString as String?,
                       let receivedBy = expense.receivedBy?.uuidString as String? {
                        
                        if userBalances[paidBy] == nil {
                            userBalances[paidBy] = ExpenseBalance(totalPaid: 0, totalOwed: 0, net: 0)
                        }
                        if userBalances[receivedBy] == nil {
                            userBalances[receivedBy] = ExpenseBalance(totalPaid: 0, totalOwed: 0, net: 0)
                        }
                        
                        // Settlement: payer's net decreases, receiver's net increases
                        let currentPayerBalance = userBalances[paidBy]!
                        let currentReceiverBalance = userBalances[receivedBy]!
                        
                        userBalances[paidBy] = ExpenseBalance(
                            totalPaid: currentPayerBalance.totalPaid,
                            totalOwed: currentPayerBalance.totalOwed,
                            net: currentPayerBalance.net - expense.amount
                        )
                        
                        userBalances[receivedBy] = ExpenseBalance(
                            totalPaid: currentReceiverBalance.totalPaid,
                            totalOwed: currentReceiverBalance.totalOwed,
                            net: currentReceiverBalance.net + expense.amount
                        )
                        
                        print("💰 [ExpensesStore] Settlement processed: \(paidBy) paid \(receivedBy) $\(expense.amount)")
                    }
                } else {
                    // Regular expenses with splits
                    for split in expense.splits {
                        let userId = split.userId.uuidString
                        
                        if userBalances[userId] == nil {
                            userBalances[userId] = ExpenseBalance(totalPaid: 0, totalOwed: 0, net: 0)
                        }
                        
                        let currentBalance = userBalances[userId]!
                        userBalances[userId] = ExpenseBalance(
                            totalPaid: currentBalance.totalPaid + (split.paidShare ?? 0),
                            totalOwed: currentBalance.totalOwed + (split.owedShare ?? 0),
                            net: currentBalance.net
                        )
                    }
                }
            }
            
            // Calculate final net balances
            for userId in userBalances.keys {
                let currentBalance = userBalances[userId]!
                let regularExpenseNet = currentBalance.totalPaid - currentBalance.totalOwed
                let settlementAdjustment = currentBalance.net // This was set by settlement expenses
                
                userBalances[userId] = ExpenseBalance(
                    totalPaid: currentBalance.totalPaid,
                    totalOwed: currentBalance.totalOwed,
                    net: regularExpenseNet + settlementAdjustment
                )
                
                print("💰 [ExpensesStore] Final balance for \(userId): paid=\(currentBalance.totalPaid), owed=\(currentBalance.totalOwed), net=\(regularExpenseNet + settlementAdjustment)")
            }
        }
        
        print("💰 [ExpensesStore] Calculated balances for \(userBalances.count) users")
        self.balances = userBalances
    }
    
    func toggleSettlementMode() {
        isSettlementMode.toggle()
        // TODO: Update party settlement mode in database
    }
    
    func updateAttendees(_ attendees: [PartyAttendee]) {
        print("💰 [ExpensesStore] Updating attendees: \(attendees.count) attendees")
        for attendee in attendees {
            print("💰 [ExpensesStore] Attendee: \(attendee.fullName) (ID: \(attendee.userId))")
        }
        self.attendees = attendees
        // Note: Balances will be loaded from database when loadAllWithAttendees is called
    }
    
    func getAttendeeName(by userId: String) -> String {
        print("💰 [ExpensesStore] getAttendeeName called for userId: \(userId)")
        print("💰 [ExpensesStore] Available attendees: \(attendees.map { "\($0.fullName) (\($0.userId.uppercased()))" })")
        
        if let attendee = attendees.first(where: { $0.userId.uppercased() == userId.uppercased() }) {
            print("💰 [ExpensesStore] Found attendee: \(attendee.fullName)")
            return attendee.fullName
        }
        
        print("💰 [ExpensesStore] No attendee found, returning fallback name")
        return "User \(userId.prefix(8))"
    }
    
    // MARK: - Expense Creation
    
    func createExpense(formData: ExpenseFormData, partyId: UUID, currentUserId: UUID) async throws {
        print("💰 [ExpensesStore] Creating expense with form data: \(formData)")
        
        // Calculate splits
        let splits = calculateSplits(from: formData)
        
        // Create expense splits for database
        let expenseSplits = splits.map { split in
            ExpenseSplitResponse(
                id: UUID(),
                expense_id: UUID(), // Will be set by database
                user_id: UUID(uuidString: split.userId) ?? UUID(),
                owed_share: split.owedShare,
                paid_share: split.paidShare,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        // Create expense for database
        let expenseResponse = ExpenseResponse(
            id: UUID(),
            party_id: partyId,
            title: formData.title,
            amount: formData.amount ?? 0.0,
            paid_by: UUID(uuidString: formData.paidBy) ?? UUID(),
            received_by: nil,
            date: ISO8601DateFormatter().string(from: formData.date),
            category: formData.category.rawValue,
            split_type: formData.splitType.rawValue,
            notes: formData.notes.isEmpty ? nil : formData.notes,
            receipt_image_url: nil,
            created_at: ISO8601DateFormatter().string(from: Date()),
            created_by: currentUserId,
            updated_at: ISO8601DateFormatter().string(from: Date()),
            expense_splits: expenseSplits
        )
        
        // Submit to database
        try await submitExpenseToDatabase(expense: expenseResponse, splits: expenseSplits)
        
        // Reload expenses and balances from database
        await loadAllWithAttendees(partyId: partyId, userId: currentUserId)
    }
    
    // MARK: - Expense Update
    func updateExpense(expenseId: UUID, formData: ExpenseFormData, partyId: UUID, currentUserId: UUID) async throws {
        print("💰 [ExpensesStore] Updating expense: \(expenseId)")
        
        // Calculate splits
        let splits = calculateSplits(from: formData)
        
        // Create expense splits for database
        let expenseSplits = splits.map { split in
            ExpenseSplitResponse(
                id: UUID(),
                expense_id: expenseId,
                user_id: UUID(uuidString: split.userId) ?? UUID(),
                owed_share: split.owedShare,
                paid_share: split.paidShare,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        // Create expense for database
        let expenseResponse = ExpenseResponse(
            id: expenseId,
            party_id: partyId,
            title: formData.title,
            amount: formData.amount ?? 0.0,
            paid_by: UUID(uuidString: formData.paidBy) ?? UUID(),
            received_by: nil,
            date: ISO8601DateFormatter().string(from: formData.date),
            category: formData.category.rawValue,
            split_type: formData.splitType.rawValue,
            notes: formData.notes.isEmpty ? nil : formData.notes,
            receipt_image_url: nil,
            created_at: ISO8601DateFormatter().string(from: Date()),
            created_by: currentUserId,
            updated_at: ISO8601DateFormatter().string(from: Date()),
            expense_splits: expenseSplits
        )
        
        try await updateExpenseInDatabase(expense: expenseResponse, splits: expenseSplits)
        
        // Reload expenses and balances from database
        await loadAllWithAttendees(partyId: partyId, userId: currentUserId)
    }
    
    // MARK: - Expense Delete
    func deleteExpense(expenseId: UUID, partyId: UUID, currentUserId: UUID) async throws {
        print("💰 [ExpensesStore] Deleting expense: \(expenseId)")
        
        try await deleteExpenseFromDatabase(expenseId: expenseId)
        
        // Reload expenses and balances from database
        await loadAllWithAttendees(partyId: partyId, userId: currentUserId)
    }
    
    private func calculateSplits(from formData: ExpenseFormData) -> [ExpenseSplitData] {
        var splits: [ExpenseSplitData] = []
        let totalAmount = formData.amount ?? 0.0
        
        for userId in formData.selectedUsers {
            let owedShare: Double
            let paidShare: Double
            
            if formData.splitType == .even {
                // Even split
                owedShare = totalAmount / Double(formData.selectedUsers.count)
            } else {
                // Custom split
                owedShare = formData.customSplits[userId] ?? 0.0
            }
            
            // Set paid share for the person who paid
            paidShare = userId == formData.paidBy ? totalAmount : 0.0
            
            splits.append(ExpenseSplitData(
                userId: userId,
                owedShare: owedShare,
                paidShare: paidShare
            ))
        }
        
        return splits
    }
    
    private func submitExpenseToDatabase(expense: ExpenseResponse, splits: [ExpenseSplitResponse]) async throws {
        print("💰 [ExpensesStore] Submitting expense to database: \(expense.title)")
        print("💰 [ExpensesStore] With \(splits.count) splits")
        
        do {
            // First, insert the expense record
                struct ExpenseInsertData: Encodable {
        let party_id: String
        let title: String
        let amount: Double
        let paid_by: String
        let received_by: String?
        let date: String
        let category: String
        let split_type: String
        let notes: String?
        let receipt_image_url: String?
        let created_at: String
        let created_by: String?
    }
            
            let expenseData = ExpenseInsertData(
                party_id: expense.party_id.uuidString,
                title: expense.title,
                amount: expense.amount,
                paid_by: expense.paid_by.uuidString,
                received_by: expense.received_by?.uuidString,
                date: expense.date,
                category: expense.category,
                split_type: expense.split_type,
                notes: expense.notes,
                receipt_image_url: expense.receipt_image_url,
                created_at: expense.created_at,
                created_by: expense.created_by?.uuidString
            )
            
            print("💰 [ExpensesStore] Inserting expense with data: \(expenseData)")
            
            let expenseResponse: [ExpenseResponse] = try await supabase
                .from("expenses")
                .insert(expenseData)
                .select()
                .execute()
                .value
            
            guard let insertedExpense = expenseResponse.first else {
                throw NSError(domain: "ExpensesStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to insert expense"])
            }
            
            print("💰 [ExpensesStore] Successfully inserted expense with ID: \(insertedExpense.id)")
            
            // Then, insert the expense splits
            struct ExpenseSplitInsertData: Encodable {
                let expense_id: String
                let user_id: String
                let owed_share: Double?
                let paid_share: Double?
                let created_at: String
            }
            
            let splitsData = splits.map { split in
                ExpenseSplitInsertData(
                    expense_id: insertedExpense.id.uuidString,
                    user_id: split.user_id.uuidString,
                    owed_share: split.owed_share,
                    paid_share: split.paid_share,
                    created_at: split.created_at
                )
            }
            
            print("💰 [ExpensesStore] Inserting \(splitsData.count) splits")
            
            let _: [ExpenseSplitResponse] = try await supabase
                .from("expense_splits")
                .insert(splitsData)
                .select()
                .execute()
                .value
            
            print("💰 [ExpensesStore] Successfully inserted all expense splits")
            
        } catch {
            print("💰 [ExpensesStore] Error submitting expense to database: \(error)")
            throw error
        }
    }
    
    private func updateExpenseInDatabase(expense: ExpenseResponse, splits: [ExpenseSplitResponse]) async throws {
        print("💰 [ExpensesStore] Updating expense in database: \(expense.title)")
        
        do {
            // First, delete existing splits for this expense
            let _: [ExpenseSplitResponse] = try await supabase
                .from("expense_splits")
                .delete()
                .eq("expense_id", value: expense.id)
                .select()
                .execute()
                .value
            
            print("💰 [ExpensesStore] Deleted existing splits for expense: \(expense.id)")
            
            // Update the expense
            struct ExpenseUpdateData: Encodable {
                let title: String
                let amount: Double
                let paid_by: String
                let received_by: String?
                let date: String
                let category: String
                let split_type: String
                let notes: String?
                let receipt_image_url: String?
                let updated_at: String
            }
            
            let expenseData = ExpenseUpdateData(
                title: expense.title,
                amount: expense.amount,
                paid_by: expense.paid_by.uuidString,
                received_by: expense.received_by?.uuidString,
                date: expense.date,
                category: expense.category,
                split_type: expense.split_type,
                notes: expense.notes,
                receipt_image_url: expense.receipt_image_url,
                updated_at: expense.updated_at ?? ISO8601DateFormatter().string(from: Date())
            )
            
            let _: [ExpenseResponse] = try await supabase
                .from("expenses")
                .update(expenseData)
                .eq("id", value: expense.id)
                .select()
                .execute()
                .value
            
            print("💰 [ExpensesStore] Successfully updated expense: \(expense.id)")
            
            // Insert new splits
            struct ExpenseSplitInsertData: Encodable {
                let expense_id: String
                let user_id: String
                let owed_share: Double?
                let paid_share: Double?
                let created_at: String
            }
            
            let splitsData = splits.map { split in
                ExpenseSplitInsertData(
                    expense_id: expense.id.uuidString,
                    user_id: split.user_id.uuidString,
                    owed_share: split.owed_share,
                    paid_share: split.paid_share,
                    created_at: split.created_at
                )
            }
            
            print("💰 [ExpensesStore] Inserting \(splitsData.count) new splits")
            
            let _: [ExpenseSplitResponse] = try await supabase
                .from("expense_splits")
                .insert(splitsData)
                .select()
                .execute()
                .value
            
            print("💰 [ExpensesStore] Successfully inserted all new expense splits")
            
        } catch {
            print("💰 [ExpensesStore] Error updating expense in database: \(error)")
            throw error
        }
    }
    
    private func deleteExpenseFromDatabase(expenseId: UUID) async throws {
        print("💰 [ExpensesStore] Deleting expense from database: \(expenseId)")
        
        do {
            // First, delete expense splits (due to foreign key constraints)
            let _: [ExpenseSplitResponse] = try await supabase
                .from("expense_splits")
                .delete()
                .eq("expense_id", value: expenseId.uuidString)
                .select()
                .execute()
                .value
            
            print("💰 [ExpensesStore] Deleted expense splits for expense: \(expenseId)")
            
            // Then, delete the expense
            let _: [ExpenseResponse] = try await supabase
                .from("expenses")
                .delete()
                .eq("id", value: expenseId.uuidString)
                .select()
                .execute()
                .value
            
            print("💰 [ExpensesStore] Successfully deleted expense: \(expenseId)")
            
        } catch {
            print("💰 [ExpensesStore] Error deleting expense from database: \(error)")
            throw error
        }
    }
}

// MARK: - Expense Form Models

enum ExpenseCategory: String, CaseIterable, Codable {
    case food = "food"
    case transportation = "transportation"
    case activity = "activity"
    case lodging = "lodging"
    case alcohol = "alcohol"
    case general = "general"
    case settlement = "settlement"
    
    var displayName: String {
        switch self {
        case .food: return "Food & Drinks"
        case .transportation: return "Transportation"
        case .activity: return "Activities"
        case .lodging: return "Lodging"
        case .alcohol: return "Alcohol"
        case .general: return "General"
        case .settlement: return "Settlement"
        }
    }
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transportation: return "car"
        case .activity: return "figure.walk"
        case .lodging: return "bed.double"
        case .alcohol: return "wineglass"
        case .general: return "dollarsign.circle"
        case .settlement: return "creditcard"
        }
    }
}

enum SplitType: String, CaseIterable, Codable {
    case even = "even"
    case custom = "custom"
    
    var displayName: String {
        switch self {
        case .even: return "Even Split"
        case .custom: return "Custom Split"
        }
    }
}

struct ExpenseFormData {
    var title: String = ""
    var amount: Double? = nil
    var category: ExpenseCategory = .general
    var paidBy: String = ""
    var splitType: SplitType = .even
    var notes: String = ""
    var date: Date = Date()
    var selectedUsers: Set<String> = []
    var customSplits: [String: Double] = [:] // userId -> amount
    
    var isValid: Bool {
        return !title.isEmpty && 
               (amount ?? 0) > 0 && 
               !paidBy.isEmpty && 
               !selectedUsers.isEmpty
    }
    
    var validationErrors: [String] {
        var errors: [String] = []
        if title.isEmpty { errors.append("Title is required") }
        if (amount ?? 0) <= 0 { errors.append("Amount must be greater than $0") }
        if paidBy.isEmpty { errors.append("Please select who paid") }
        if selectedUsers.isEmpty { errors.append("Please select at least one person to split with") }
        return errors
    }
}

struct ExpenseSplitData: Identifiable {
    let id = UUID()
    let userId: String
    var owedShare: Double
    var paidShare: Double
    
    var netAmount: Double {
        return paidShare - owedShare
    }
}

// MARK: - Database Response Models

struct UserExpenseBalanceResponse: Codable {
    let party_id: String?
    let user_id: String?
    let total_paid: Double?
    let total_owed: Double?
    let net_balance: Double?
}

struct ExpenseResponse: Codable {
    let id: UUID
    let party_id: UUID
    let title: String
    let amount: Double
    let paid_by: UUID
    let received_by: UUID?
    let date: String
    let category: String
    let split_type: String
    let notes: String?
    let receipt_image_url: String?
    let created_at: String
    let created_by: UUID?
    let updated_at: String?
    let expense_splits: [ExpenseSplitResponse]?
}

struct ExpenseSplitResponse: Codable {
    let id: UUID
    let expense_id: UUID
    let user_id: UUID
    let owed_share: Double?
    let paid_share: Double?
    let created_at: String
}

// MARK: - App Models

struct Expense: Identifiable, Codable {
    let id: UUID
    let title: String
    let amount: Double
    let paidBy: UUID
    let receivedBy: UUID?
    let date: Date
    let category: String
    let splitType: String
    let notes: String?
    let receiptImageUrl: String?
    let createdAt: Date
    let createdBy: UUID?
    let updatedAt: Date?
    let splits: [ExpenseSplit]
    
    init(from response: ExpenseResponse) throws {
        self.id = response.id
        self.title = response.title
        self.amount = response.amount
        self.paidBy = response.paid_by
        self.receivedBy = response.received_by
        self.category = response.category
        self.splitType = response.split_type
        self.notes = response.notes
        self.receiptImageUrl = response.receipt_image_url
        self.createdBy = response.created_by
        
        // Parse dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.date = dateFormatter.date(from: response.date) ?? Date()
        
        let isoFormatter = ISO8601DateFormatter()
        self.createdAt = isoFormatter.date(from: response.created_at) ?? Date()
        
        if let updatedAtString = response.updated_at {
            self.updatedAt = isoFormatter.date(from: updatedAtString)
        } else {
            self.updatedAt = nil
        }
        
        // Convert expense splits
        self.splits = response.expense_splits?.compactMap { splitResponse in
            ExpenseSplit(from: splitResponse)
        } ?? []
    }
}

struct ExpenseSplit: Identifiable, Codable {
    let id: UUID
    let expenseId: UUID
    let userId: UUID
    let owedShare: Double?
    let paidShare: Double?
    let createdAt: Date
    
    init(from response: ExpenseSplitResponse) {
        self.id = response.id
        self.expenseId = response.expense_id
        self.userId = response.user_id
        self.owedShare = response.owed_share
        self.paidShare = response.paid_share
        
        let isoFormatter = ISO8601DateFormatter()
        self.createdAt = isoFormatter.date(from: response.created_at) ?? Date()
    }
}

struct ExpenseBalance {
    let totalPaid: Double
    let totalOwed: Double
    let net: Double
}


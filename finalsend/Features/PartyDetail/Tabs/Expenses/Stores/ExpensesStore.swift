import Foundation
import Supabase

@MainActor
class ExpensesStore: ObservableObject {
    @Published var expenses: [Expense] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func loadAllWithAttendees(partyId: UUID, userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        // For now, return empty array to prevent crashes
        // This can be implemented later with actual Supabase queries
        expenses = []
    }
    
    func cleanup() {
        // Cleanup resources
    }
}

// Basic Expense model to prevent compilation errors
struct Expense: Identifiable, Codable {
    let id: UUID
    let title: String
    let amount: Double
    let paidBy: UUID
    let partyId: UUID
    let createdAt: Date
    
    init(id: UUID = UUID(), title: String, amount: Double, paidBy: UUID, partyId: UUID, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.amount = amount
        self.paidBy = paidBy
        self.partyId = partyId
        self.createdAt = createdAt
    }
}


import Foundation
import Supabase

@MainActor
class PackingStore: ObservableObject {
    @Published var items: [PackingItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func load(partyId: UUID, userId: UUID) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // For now, return empty array to prevent crashes
            // This can be implemented later with actual Supabase queries
            items = []
        } catch {
            self.error = error
        }
    }
    
    func teardown() {
        // Cleanup resources
    }
}

// Basic PackingItem model to prevent compilation errors
struct PackingItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String?
    let partyId: UUID
    let createdBy: UUID
    let createdAt: Date
    
    init(id: UUID = UUID(), title: String, description: String? = nil, partyId: UUID, createdBy: UUID, createdAt: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.partyId = partyId
        self.createdBy = createdBy
        self.createdAt = createdAt
    }
}


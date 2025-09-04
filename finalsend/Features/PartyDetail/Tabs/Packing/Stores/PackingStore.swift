import Foundation
import Supabase

@MainActor
class PackingStore: ObservableObject {
    @Published var items: [PackingItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let packingService: PackingService
    
    init(supabase: SupabaseClient) {
        self.packingService = PackingService(supabase: supabase)
    }
    
    func load(partyId: UUID, userId: UUID) async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            items = try await packingService.getPackingItems(partyId: partyId, userId: userId)
        } catch {
            self.error = error
            print("Error loading packing items: \(error)")
        }
    }
    
    func addItem(partyId: UUID, title: String, description: String?, userId: UUID) async {
        do {
            let newItem = try await packingService.addPackingItem(
                partyId: partyId,
                title: title,
                description: description,
                userId: userId
            )
            items.append(newItem)
        } catch {
            self.error = error
            print("Error adding packing item: \(error)")
        }
    }
    
    func updateItem(itemId: UUID, title: String, description: String?) async {
        do {
            let updatedItem = try await packingService.updatePackingItem(
                itemId: itemId,
                title: title,
                description: description
            )
            
            if let index = items.firstIndex(where: { $0.id == itemId }) {
                items[index] = updatedItem
            }
        } catch {
            self.error = error
            print("Error updating packing item: \(error)")
        }
    }
    
    func deleteItem(itemId: UUID) async {
        do {
            try await packingService.deletePackingItem(itemId: itemId)
            items.removeAll { $0.id == itemId }
        } catch {
            self.error = error
            print("Error deleting packing item: \(error)")
        }
    }
    
    func togglePackedStatus(itemId: UUID, userId: UUID, isPacked: Bool) async {
        do {
            try await packingService.togglePackingStatus(
                itemId: itemId,
                userId: userId,
                isPacked: isPacked
            )
            
            if let index = items.firstIndex(where: { $0.id == itemId }) {
                items[index].isPacked = isPacked
            }
        } catch {
            self.error = error
            print("Error toggling packing status: \(error)")
        }
    }
    
    func teardown() {
        // Cleanup resources
    }
}

// PackingItem model matching database schema
struct PackingItem: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String?
    let partyId: UUID
    let createdBy: UUID
    let createdAt: Date
    let updatedAt: Date
    var isPacked: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case partyId = "party_id"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case isPacked = "is_packed"
    }
    
    init(id: UUID = UUID(), title: String, description: String? = nil, partyId: UUID, createdBy: UUID, createdAt: Date = Date(), updatedAt: Date = Date(), isPacked: Bool = false) {
        self.id = id
        self.title = title
        self.description = description
        self.partyId = partyId
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isPacked = isPacked
    }
}


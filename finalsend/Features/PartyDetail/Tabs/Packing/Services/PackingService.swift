import Foundation
import Supabase

class PackingService {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func getPackingItems(partyId: UUID, userId: UUID) async throws -> [PackingItem] {
        // Get packing items created by the current user
        let response: [PackingItem] = try await supabase
            .from("packing_items")
            .select()
            .eq("party_id", value: partyId)
            .eq("created_by", value: userId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        // Get packing status for these items
        let itemIds = response.map { $0.id }
        if !itemIds.isEmpty {
            let statusResponse: [PackingItemStatus] = try await supabase
                .from("packing_item_status")
                .select()
                .in("packing_item_id", values: itemIds)
                .eq("user_id", value: userId)
                .execute()
                .value
            
            let statusMap = Dictionary(uniqueKeysWithValues: statusResponse.map { ($0.packingItemId, $0.isPacked) })
            
            return response.map { item in
                var updatedItem = item
                updatedItem.isPacked = statusMap[item.id] ?? false
                return updatedItem
            }
        }
        
        return response
    }
    
    func addPackingItem(partyId: UUID, title: String, description: String?, userId: UUID) async throws -> PackingItem {
        let newItem = PackingItem(
            title: title,
            description: description,
            partyId: partyId,
            createdBy: userId
        )
        
        let response: PackingItem = try await supabase
            .from("packing_items")
            .insert(newItem)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updatePackingItem(itemId: UUID, title: String, description: String?) async throws -> PackingItem {
        struct UpdateData: Encodable {
            let title: String
            let description: String?
            let updated_at: String
        }
        
        let updateData = UpdateData(
            title: title,
            description: description,
            updated_at: ISO8601DateFormatter().string(from: Date())
        )
        
        let response: PackingItem = try await supabase
            .from("packing_items")
            .update(updateData)
            .eq("id", value: itemId)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func deletePackingItem(itemId: UUID) async throws {
        try await supabase
            .from("packing_items")
            .delete()
            .eq("id", value: itemId)
            .execute()
    }
    
    func togglePackingStatus(itemId: UUID, userId: UUID, isPacked: Bool) async throws {
        // First, try to update existing record
        let existingResponse: [PackingItemStatus] = try await supabase
            .from("packing_item_status")
            .select()
            .eq("packing_item_id", value: itemId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        if let existingStatus = existingResponse.first {
            // Update existing record
            struct StatusUpdateData: Encodable {
                let is_packed: Bool
                let updated_at: String
            }
            
            let updateData = StatusUpdateData(
                is_packed: isPacked,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await supabase
                .from("packing_item_status")
                .update(updateData)
                .eq("id", value: existingStatus.id)
                .execute()
        } else {
            // Insert new record
            let newStatus = PackingItemStatus(
                packingItemId: itemId,
                userId: userId,
                isPacked: isPacked
            )
            
            try await supabase
                .from("packing_item_status")
                .insert(newStatus)
                .execute()
        }
    }
}

// PackingItemStatus model for tracking user's packing status
struct PackingItemStatus: Identifiable, Codable {
    let id: UUID
    let packingItemId: UUID
    let userId: UUID
    let isPacked: Bool
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case packingItemId = "packing_item_id"
        case userId = "user_id"
        case isPacked = "is_packed"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    init(id: UUID = UUID(), packingItemId: UUID, userId: UUID, isPacked: Bool, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.packingItemId = packingItemId
        self.userId = userId
        self.isPacked = isPacked
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

class PackingRealtime {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // Basic realtime methods - can be implemented later
}


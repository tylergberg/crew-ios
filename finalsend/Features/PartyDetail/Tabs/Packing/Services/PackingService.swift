import Foundation
import Supabase

class PackingService {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func getPackingItems(partyId: UUID, userId: UUID) async throws -> [PackingItem] {
        let response: [PackingItem] = try await supabase
            .from("packing_items")
            .select()
            .eq("party_id", value: partyId)
            .eq("user_id", value: userId)
            .order("created_at", ascending: true)
            .execute()
            .value
        return response
    }
    
    func addPackingItem(partyId: UUID, title: String, description: String?, userId: UUID) async throws -> PackingItem {
        struct InsertData: Encodable {
            let party_id: UUID
            let user_id: UUID
            let title: String
            let description: String?
            let is_packed: Bool
        }
        let insert = InsertData(party_id: partyId, user_id: userId, title: title, description: description, is_packed: false)
        let response: PackingItem = try await supabase
            .from("packing_items")
            .insert(insert)
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
        let updateData = UpdateData(title: title, description: description, updated_at: ISO8601DateFormatter().string(from: Date()))
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
        struct StatusUpdateData: Encodable {
            let is_packed: Bool
            let updated_at: String
        }
        let updateData = StatusUpdateData(is_packed: isPacked, updated_at: ISO8601DateFormatter().string(from: Date()))
        try await supabase
            .from("packing_items")
            .update(updateData)
            .eq("id", value: itemId)
            .eq("user_id", value: userId)
            .execute()
    }
}

class PackingRealtime {
    private let client: SupabaseClient
    
    init(client: SupabaseClient) {
        self.client = client
    }
    
    // Basic realtime methods - can be implemented later
}


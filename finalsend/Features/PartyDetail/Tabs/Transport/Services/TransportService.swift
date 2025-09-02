import Foundation
import Supabase

@MainActor
class TransportService: ObservableObject {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    func fetchTransportations(partyId: UUID) async throws -> [Transportation] {
        let response: [Transportation] = try await supabase
            .from("transportations")
            .select()
            .eq("party_id", value: partyId)
            .order("created_at", ascending: false)
            .execute()
            .value
        
        return response
    }
    
    func createTransportation(_ transportation: Transportation) async throws -> Transportation {
        let response: Transportation = try await supabase
            .from("transportations")
            .insert(transportation)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateTransportation(_ transportation: Transportation) async throws -> Transportation {
        let response: Transportation = try await supabase
            .from("transportations")
            .update(transportation)
            .eq("id", value: transportation.id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func deleteTransportation(_ transportationId: UUID) async throws {
        try await supabase
            .from("transportations")
            .delete()
            .eq("id", value: transportationId)
            .execute()
    }
}

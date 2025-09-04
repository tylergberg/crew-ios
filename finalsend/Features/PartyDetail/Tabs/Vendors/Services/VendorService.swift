import Foundation
import Supabase

final class VendorService {
    private let client: SupabaseClient

    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    func fetchVendors(cityId: UUID) async throws -> [Vendor] {
        do {
            let vendors: [Vendor] = try await client
                .from("vendors")
                .select()
                .eq("city_id", value: cityId)
                .order("rating", ascending: false)
                .execute()
                .value
            return vendors
        } catch {
            AppLogger.error("VendorService: Error fetching vendors for city \(cityId): \(error)")
            throw error
        }
    }
}



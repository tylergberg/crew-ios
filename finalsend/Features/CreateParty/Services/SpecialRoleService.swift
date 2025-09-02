import Foundation
import Supabase

enum SpecialRoleError: Error, LocalizedError {
    case networkError(Error)
    case invalidRole
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidRole:
            return "Invalid role specified"
        }
    }
}

protocol SpecialRoleServiceType {
    func assignSpecialRole(partyId: UUID, partyType: String) async throws
}

class SpecialRoleService: SpecialRoleServiceType {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    /// Assigns special role based on party type (best-effort, non-blocking)
    func assignSpecialRole(partyId: UUID, partyType: String) async throws {
        let role: String
        
        switch partyType {
        case "bachelor":
            role = "groom"
        case "bachelorette":
            role = "bride"
        default:
            throw SpecialRoleError.invalidRole
        }
        
        do {
            print("👑 Assigning special role '\(role)' for party: \(partyId)")
            
            // Call the RPC function (same as web)
            let response: [String: String] = try await client
                .rpc("assign_special_role", params: [
                    "party_id": partyId.uuidString,
                    "role_type": role
                ])
                .execute()
                .value
            
            print("✅ Special role assigned successfully: \(response)")
            
        } catch {
            print("⚠️ Special role assignment failed (non-blocking): \(error)")
            // Don't re-throw - this is best-effort only
        }
    }
}

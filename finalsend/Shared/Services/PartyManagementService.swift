import Foundation
import Supabase

enum PartyManagementError: Error, LocalizedError {
    case networkError(Error)
    case unauthorized
    case partyNotFound
    case deletionFailed
    case invalidPartyId
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .partyNotFound:
            return "Party not found"
        case .deletionFailed:
            return "Failed to delete party"
        case .invalidPartyId:
            return "Invalid party ID"
        }
    }
}

protocol PartyManagementServiceType {
    func deleteParty(partyId: String) async throws -> Bool
    func updateParty(partyId: String, updates: [String: Any]) async throws -> Bool
}

class PartyManagementService: PartyManagementServiceType {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    /// Deletes a party and all its associated data
    /// This follows the same pattern as the web version, using direct database operations
    func deleteParty(partyId: String) async throws -> Bool {
        guard !partyId.isEmpty else {
            throw PartyManagementError.invalidPartyId
        }
        
        // Check authentication state and get session
        let session: Session
        do {
            session = try await client.auth.session
            print("🔐 User authenticated: \(session.user.id.uuidString)")
            print("🔐 User email: \(session.user.email ?? "no email")")
            
            // Ensure we have a valid session
            guard !session.accessToken.isEmpty else {
                print("❌ Empty access token")
                throw PartyManagementError.unauthorized
            }
        } catch {
            print("❌ User not authenticated: \(error)")
            throw PartyManagementError.unauthorized
        }
        
        do {
            print("🗑️ Attempting to delete party: \(partyId)")
            
            // First, verify the party exists and user has admin permissions
            let partyResponse: [PartyRow] = try await client
                .from("parties")
                .select("id, name")
                .eq("id", value: partyId)
                .execute()
                .value
            
            guard let party = partyResponse.first else {
                print("❌ Party not found: \(partyId)")
                throw PartyManagementError.partyNotFound
            }
            
            print("✅ Found party: \(party.name ?? "Unknown")")
            
            // Check if user is admin for this party
            let membershipResponse: [PartyMemberRoleRow] = try await client
                .from("party_members")
                .select("role")
                .eq("party_id", value: partyId)
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value
            
            guard let membership = membershipResponse.first,
                  membership.role == "admin" else {
                print("❌ User is not admin for party: \(partyId)")
                throw PartyManagementError.unauthorized
            }
            
            print("✅ User has admin permissions for party deletion")
            
            // Call the delete_party_by_admin RPC function (same as web version)
            do {
                print("🗑️ Calling delete_party_by_admin RPC function...")
                
                let result: Bool = try await client
                    .rpc("delete_party_by_admin", params: ["p_party_id": partyId])
                    .execute()
                    .value
                
                if result {
                    print("✅ Party deletion RPC function returned success")
                    
                    // Verify the deletion actually worked
                    print("🔍 Verifying party deletion...")
                    let verificationResponse: [PartyRow] = try await client
                        .from("parties")
                        .select("id, name")
                        .eq("id", value: partyId)
                        .execute()
                        .value
                    
                    if verificationResponse.isEmpty {
                        print("✅ Party deletion verified - party no longer exists")
                        return true
                    } else {
                        print("❌ Party deletion failed - party still exists: \(verificationResponse.first?.name ?? "Unknown")")
                        throw PartyManagementError.deletionFailed
                    }
                } else {
                    print("❌ Party deletion RPC function returned false")
                    throw PartyManagementError.deletionFailed
                }
                
            } catch {
                print("❌ Party deletion RPC function failed: \(error)")
                print("❌ Error type: \(type(of: error))")
                print("❌ Error description: \(error.localizedDescription)")
                
                // Try to get more details about the error
                if let supabaseError = error as? PostgrestError {
                    print("❌ Supabase error details: \(supabaseError)")
                }
                
                throw error
            }
            
        } catch {
            print("❌ Error deleting party: \(error)")
            
            // Handle specific errors based on error description
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("not found") || errorDescription.contains("404") {
                throw PartyManagementError.partyNotFound
            } else if errorDescription.contains("unauthorized") || errorDescription.contains("403") {
                throw PartyManagementError.unauthorized
            }
            
            throw PartyManagementError.networkError(error)
        }
    }
    
    /// Updates party details
    func updateParty(partyId: String, updates: [String: Any]) async throws -> Bool {
        guard !partyId.isEmpty else {
            throw PartyManagementError.invalidPartyId
        }
        
        // Check authentication state and get session
        let session: Session
        do {
            session = try await client.auth.session
            print("🔐 User authenticated: \(session.user.id.uuidString)")
            
            // Ensure we have a valid session
            guard !session.accessToken.isEmpty else {
                print("❌ Empty access token")
                throw PartyManagementError.unauthorized
            }
        } catch {
            print("❌ User not authenticated: \(error)")
            throw PartyManagementError.unauthorized
        }
        
        print("✏️ Updating party: \(partyId) with updates: \(updates)")
        
        do {
            // First, verify the party exists and user has admin permissions
            let partyResponse: [PartyRow] = try await client
                .from("parties")
                .select("id, name")
                .eq("id", value: partyId)
                .execute()
                .value
            
            guard let party = partyResponse.first else {
                print("❌ Party not found: \(partyId)")
                throw PartyManagementError.partyNotFound
            }
            
            print("✅ Found party: \(party.name ?? "Unknown")")
            
            // Check if user is admin for this party
            let membershipResponse: [PartyMemberRoleRow] = try await client
                .from("party_members")
                .select("role")
                .eq("party_id", value: partyId)
                .eq("user_id", value: session.user.id.uuidString)
                .execute()
                .value
            
            guard let membership = membershipResponse.first,
                  membership.role == "admin" else {
                print("❌ User is not admin for party: \(partyId)")
                throw PartyManagementError.unauthorized
            }
            
            print("✅ User has admin permissions for party update")
            
            // Convert updates to Encodable format
            let encodableUpdates = updates.mapValues { value -> String in
                if let stringValue = value as? String {
                    return stringValue
                } else if let intValue = value as? Int {
                    return String(intValue)
                } else if let doubleValue = value as? Double {
                    return String(doubleValue)
                } else if let boolValue = value as? Bool {
                    return String(boolValue)
                } else {
                    return String(describing: value)
                }
            }
            
            // Perform the update
            let updateResponse: [PartyRow] = try await client
                .from("parties")
                .update(encodableUpdates)
                .eq("id", value: partyId)
                .select("id, name")
                .execute()
                .value
            
            if let updatedParty = updateResponse.first {
                print("✅ Party updated successfully: \(updatedParty.name ?? "Unknown")")
                
                // Post notification to refresh party data
                NotificationCenter.default.post(name: .refreshPartyData, object: nil)
                
                return true
            } else {
                print("❌ Party update failed - no response")
                throw PartyManagementError.networkError(NSError(domain: "PartyUpdate", code: 500, userInfo: [NSLocalizedDescriptionKey: "Update failed"]))
            }
            
        } catch {
            print("❌ Error updating party: \(error)")
            
            // Handle specific errors based on error description
            let errorDescription = error.localizedDescription.lowercased()
            if errorDescription.contains("not found") || errorDescription.contains("404") {
                throw PartyManagementError.partyNotFound
            } else if errorDescription.contains("unauthorized") || errorDescription.contains("403") {
                throw PartyManagementError.unauthorized
            }
            
            throw PartyManagementError.networkError(error)
        }
    }
}

// MARK: - Supporting Types

private struct PartyRow: Decodable {
    let id: String
    let name: String?
}

private struct PartyMemberRoleRow: Decodable {
    let role: String
}

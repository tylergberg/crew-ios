import Foundation
import Supabase

enum PartyCreationError: Error, LocalizedError {
    case networkError(Error)
    case invalidDraft
    case creationFailed
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidDraft:
            return "Invalid party data"
        case .creationFailed:
            return "Failed to create party"
        }
    }
}

protocol PartyCreationServiceType {
    func createParty(from draft: PartyDraft) async throws -> UUID
    func fetchParty(partyId: UUID) async throws -> PartyModel
}

class PartyCreationService: PartyCreationServiceType {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    /// Creates a party from the draft and returns the new party ID
    func createParty(from draft: PartyDraft) async throws -> UUID {
        guard draft.isValid else {
            throw PartyCreationError.invalidDraft
        }
        
        // Check authentication state
        do {
            let session = try await client.auth.session
            print("🔐 User authenticated: \(session.user.id.uuidString)")
            print("🔐 User email: \(session.user.email ?? "no email")")
            
            // Ensure we have a valid session
            guard !session.accessToken.isEmpty else {
                print("❌ Empty access token")
                throw PartyCreationError.networkError(NSError(domain: "Auth", code: 401, userInfo: [NSLocalizedDescriptionKey: "Invalid session"]))
            }
        } catch {
            print("❌ User not authenticated: \(error)")
            throw PartyCreationError.networkError(error)
        }
        
        // Get current user ID for created_by field
        let session = try await client.auth.session
        let currentUserId = session.user.id.uuidString
        
        // Build the payload according to web contract
        let payload = PartyCreationPayload(
            name: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
            description: nil, // Removed description field
            startDate: draft.startDate.map { CreatePartyValidators.formatDateOnly($0) },
            endDate: draft.endDate.map { CreatePartyValidators.formatDateOnly($0) },
            cityId: draft.cityId?.uuidString,
            location: nil,
            partyType: draft.finalPartyType.isEmpty ? nil : draft.finalPartyType,
            partyVibeTags: draft.vibeTags.isEmpty ? nil : draft.vibeTags,
            coverImageURL: draft.coverImageURL,
            createdBy: currentUserId
        )
        
        print("🔍 Payload details:")
        print("  - name: \(payload.name)")
        print("  - description: \(payload.description ?? "nil")")
        print("  - startDate: \(payload.startDate ?? "nil")")
        print("  - endDate: \(payload.endDate ?? "nil")")
        print("  - cityId: \(payload.cityId ?? "nil")")
        print("  - partyType: \(payload.partyType ?? "nil")")
        print("  - vibeTags: \(payload.partyVibeTags ?? [])")
        print("  - createdBy: \(payload.createdBy)")
        
        print("🎉 Creating party with payload: \(payload)")
        
        let response: PartyCreationResponse = try await client
            .from("parties")
            .insert(payload)
            .select("id")
            .single()
            .execute()
            .value
        
        print("✅ Party created successfully with ID: \(response.id)")
        return response.id
    }
    
    /// Fetches party data by ID
    func fetchParty(partyId: UUID) async throws -> PartyModel {
        let response: PartyModel = try await client
            .from("parties")
            .select("""
                id,
                name,
                description,
                start_date,
                end_date,
                location,
                party_type,
                party_vibe_tags,
                created_by,
                city_id,
                social_links,
                cover_image_url,
                theme_id,
                cities:city_id (
                    id,
                    city,
                    state_or_province,
                    country,
                    timezone
                )
            """)
            .eq("id", value: partyId)
            .single()
            .execute()
            .value
        
        print("✅ Party data fetched successfully for ID: \(partyId)")
        return response
    }
}

// Payload structure for party creation
struct PartyCreationPayload: Codable {
    let name: String
    let description: String?
    let startDate: String?
    let endDate: String?
    let cityId: String?
    let location: String?
    let partyType: String?
    let partyVibeTags: [String]?
    let coverImageURL: String?
    let createdBy: String
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case startDate = "start_date"
        case endDate = "end_date"
        case cityId = "city_id"
        case location
        case partyType = "party_type"
        case partyVibeTags = "party_vibe_tags"
        case coverImageURL = "cover_image_url"
        case createdBy = "created_by"
    }
}

// Response structure for party creation
struct PartyCreationResponse: Codable {
    let id: UUID
}

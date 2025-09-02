import Foundation

struct InviteRecord: Decodable {
    let party_id: UUID
    let created_at: String?
    let expires_at: String?
}

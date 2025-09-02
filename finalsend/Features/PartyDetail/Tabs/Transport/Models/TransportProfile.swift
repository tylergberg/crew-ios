import Foundation

// Simplified profile structure for transportation feature
struct TransportProfile: Identifiable, Codable, Hashable {
    let id: String
    let fullName: String?
    let avatarUrl: String?
    
    var initials: String {
        guard let fullName = fullName, !fullName.isEmpty else { return "??" }
        let components = fullName.components(separatedBy: " ")
        if components.count >= 2 {
            let first = components[0].prefix(1).uppercased()
            let last = components[1].prefix(1).uppercased()
            return "\(first)\(last)"
        } else if components.count == 1 {
            return components[0].prefix(1).uppercased()
        }
        return "??"
    }
    
    init(
        id: String,
        fullName: String? = nil,
        avatarUrl: String? = nil
    ) {
        self.id = id
        self.fullName = fullName
        self.avatarUrl = avatarUrl
    }
    
    // CodingKeys to handle snake_case from database
    enum CodingKeys: String, CodingKey {
        case id, fullName = "full_name", avatarUrl = "avatar_url"
    }
}

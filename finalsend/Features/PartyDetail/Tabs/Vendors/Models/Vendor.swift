import Foundation

struct Vendor: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let types: [String]
    let description: String?
    let location: String?
    let websiteUrl: String?
    let phone: String?
    let email: String?
    let imageUrl: String?
    let priceRange: String?
    let rating: Decimal?
    let createdAt: Date?
    let createdBy: UUID?
    let cityId: UUID?

    enum CodingKeys: String, CodingKey {
        case id, name, types, description, location, phone, email
        case websiteUrl = "website_url"
        case imageUrl = "image_url"
        case priceRange = "price_range"
        case rating
        case createdAt = "created_at"
        case createdBy = "created_by"
        case cityId = "city_id"
    }
}



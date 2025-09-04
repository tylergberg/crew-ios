import Foundation

// MARK: - Gallery Item Model
struct GalleryItem: Identifiable, Codable, Equatable {
    let id: UUID
    let partyId: UUID
    let userId: UUID
    let fileUrl: String
    let fileType: String // "image" or "video"
    let fileSize: Int?
    let filename: String
    let createdAt: Date
    let updatedAt: Date
    let user: GalleryUser?
    
    // Computed properties
    var isImage: Bool {
        return fileType == "image"
    }
    
    var isVideo: Bool {
        return fileType == "video"
    }
    
    var signedUrl: String? // Will be populated by the service
    
    enum CodingKeys: String, CodingKey {
        case id
        case partyId = "party_id"
        case userId = "user_id"
        case fileUrl = "file_url"
        case fileType = "file_type"
        case fileSize = "file_size"
        case filename
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
        case signedUrl = "signed_url"
    }
}

// MARK: - Gallery Comment Model
struct GalleryComment: Identifiable, Codable, Equatable {
    let id: UUID
    let galleryItemId: UUID
    let userId: UUID
    let text: String
    let createdAt: Date
    let updatedAt: Date
    let user: GalleryUser?
    
    enum CodingKeys: String, CodingKey {
        case id
        case galleryItemId = "gallery_item_id"
        case userId = "user_id"
        case text
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case user
    }
}

// MARK: - Upload Progress Model
struct UploadProgress: Identifiable, Equatable {
    let id: String
    let filename: String
    let progress: Double // 0.0 to 1.0
    let status: UploadStatus
    let error: String?
    
    enum UploadStatus: String, CaseIterable {
        case pending = "pending"
        case uploading = "uploading"
        case completed = "completed"
        case failed = "failed"
    }
}

// MARK: - Gallery Upload Request
struct GalleryUploadRequest {
    let partyId: UUID
    let files: [UploadFile]
    
    struct UploadFile {
        let data: Data
        let filename: String
        let mimeType: String
        let fileType: String // "image" or "video"
    }
}

// MARK: - Gallery Response Models
struct GalleryResponse: Codable {
    let items: [GalleryItem]
    let hasMore: Bool
    let nextCursor: String?
}

// MARK: - User Model for Gallery (simplified version of ProfileResponse)
struct GalleryUser: Identifiable, Codable, Equatable {
    let id: UUID
    let fullName: String?
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"
        case avatarUrl = "avatar_url"
    }
    
    var displayName: String {
        return fullName ?? "Unknown User"
    }
}

// MARK: - Social Interactions
struct GalleryLike: Codable, Identifiable {
    let id: UUID
    let galleryItemId: UUID
    let userId: UUID
    let createdAt: Date
    let user: GalleryUser?
    
    enum CodingKeys: String, CodingKey {
        case id
        case galleryItemId = "gallery_item_id"
        case userId = "user_id"
        case createdAt = "created_at"
        case user
    }
}

struct GalleryItemStats: Codable {
    let likesCount: Int
    let commentsCount: Int
    let isLikedByCurrentUser: Bool
    
    enum CodingKeys: String, CodingKey {
        case likesCount = "likes_count"
        case commentsCount = "comments_count"
        case isLikedByCurrentUser = "is_liked_by_current_user"
    }
}

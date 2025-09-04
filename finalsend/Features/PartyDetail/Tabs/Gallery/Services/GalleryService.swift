import Foundation
import Supabase
import Combine

@MainActor
class GalleryService: ObservableObject {
    static let shared = GalleryService()
    
    // MARK: - Published Properties
    @Published var galleryItems: [GalleryItem] = []
    @Published var isLoading = false
    @Published var isUploading = false
    @Published var uploadProgress: [UploadProgress] = []
    @Published var error: String?
    
    // MARK: - Private Properties
    private let supabase: SupabaseClient
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    private init() {
        self.supabase = SupabaseManager.shared.client
    }
    
    // MARK: - Public Methods
    
    /// Fetch gallery items for a party
    func fetchGalleryItems(for partyId: UUID, limit: Int = 20, offset: Int = 0) async {
        isLoading = true
        error = nil
        
        do {
            let response: [GalleryItem] = try await supabase
                .from("gallery_items")
                .select("""
                    *,
                    user:profiles(id, full_name, avatar_url)
                """)
                .eq("party_id", value: partyId)
                .order("created_at", ascending: false)
                .range(from: offset, to: offset + limit - 1)
                .execute()
                .value
            
            // Generate signed URLs for each item
            print("📸 Fetched \(response.count) gallery items")
            for item in response {
                print("📸 Item: \(item.filename) - URL: \(item.fileUrl)")
            }
            
            let itemsWithSignedUrls = await generateSignedUrls(for: response)
            
            if offset == 0 {
                // First load - replace all items
                self.galleryItems = itemsWithSignedUrls
            } else {
                // Pagination - append new items
                self.galleryItems.append(contentsOf: itemsWithSignedUrls)
            }
            
            self.isLoading = false
            
        } catch {
            self.error = "Failed to load gallery: \(error.localizedDescription)"
            self.isLoading = false
        }
    }
    
    /// Load more gallery items (pagination)
    func loadMoreGalleryItems(for partyId: UUID) async {
        guard !isLoading else { return }
        
        let currentCount = galleryItems.count
        await fetchGalleryItems(for: partyId, limit: 20, offset: currentCount)
    }
    
    /// Upload files to gallery
    func uploadFiles(_ files: [GalleryUploadRequest.UploadFile], to partyId: UUID) async {
        isUploading = true
        error = nil
        
        // Initialize upload progress
        let progressItems = files.enumerated().map { index, file in
            UploadProgress(
                id: "\(Date().timeIntervalSince1970)-\(index)",
                filename: file.filename,
                progress: 0.0,
                status: .pending,
                error: nil
            )
        }
        uploadProgress = progressItems
        
        // Upload files concurrently
        await withTaskGroup(of: Void.self) { group in
            for (index, file) in files.enumerated() {
                group.addTask {
                    await self.uploadSingleFile(file, at: index, partyId: partyId)
                }
            }
        }
        
        // Refresh gallery after uploads complete
        await fetchGalleryItems(for: partyId)
        isUploading = false
    }
    
    /// Delete a gallery item
    func deleteItem(_ item: GalleryItem) async -> Bool {
        do {
            // Delete from storage first
            let filePath = item.fileUrl
            try await supabase.storage
                .from("gallery")
                .remove(paths: [filePath])
            
            // Delete from database
            try await supabase
                .from("gallery_items")
                .delete()
                .eq("id", value: item.id)
                .execute()
            
            // Remove from local array
            galleryItems.removeAll { $0.id == item.id }
            
            return true
        } catch {
            self.error = "Failed to delete item: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Add comment to gallery item
    func addComment(_ text: String, to item: GalleryItem) async -> Bool {
        guard let userId = await getCurrentUserId() else {
            error = "User not authenticated"
            return false
        }
        
        do {
            let comment = GalleryComment(
                id: UUID(),
                galleryItemId: item.id,
                userId: userId,
                text: text,
                createdAt: Date(),
                updatedAt: Date(),
                user: nil
            )
            
            try await supabase
                .from("gallery_comments")
                .insert(comment)
                .execute()
            
            return true
        } catch {
            self.error = "Failed to add comment: \(error.localizedDescription)"
            return false
        }
    }
    
    /// Fetch comments for a gallery item
    func fetchComments(for item: GalleryItem) async -> [GalleryComment] {
        do {
            let comments: [GalleryComment] = try await supabase
                .from("gallery_comments")
                .select("""
                    *,
                    user:profiles(id, full_name, avatar_url)
                """)
                .eq("gallery_item_id", value: item.id)
                .order("created_at", ascending: true)
                .execute()
                .value
            
            return comments
        } catch {
            self.error = "Failed to load comments: \(error.localizedDescription)"
            return []
        }
    }
    
    /// Get stats (likes and comments count) for a gallery item
    func getItemStats(for item: GalleryItem) async -> GalleryItemStats {
        do {
            // Get comments count
            let commentsCount: Int = try await supabase
                .from("gallery_comments")
                .select("id", head: true, count: .exact)
                .eq("gallery_item_id", value: item.id)
                .execute()
                .count ?? 0
            
            // For now, return 0 likes since we don't have a likes table yet
            // TODO: Implement likes table and functionality
            let likesCount = 0
            let isLikedByCurrentUser = false
            
            return GalleryItemStats(
                likesCount: likesCount,
                commentsCount: commentsCount,
                isLikedByCurrentUser: isLikedByCurrentUser
            )
        } catch {
            self.error = "Failed to load item stats: \(error.localizedDescription)"
            return GalleryItemStats(likesCount: 0, commentsCount: 0, isLikedByCurrentUser: false)
        }
    }
    
    /// Start real-time updates for gallery (placeholder for future implementation)
    func startRealtimeUpdates(for partyId: UUID) {
        // TODO: Implement realtime updates
        print("Realtime updates not yet implemented for gallery")
    }
    
    /// Stop real-time updates
    func stopRealtimeUpdates() {
        // TODO: Implement realtime cleanup
        print("Realtime cleanup not yet implemented for gallery")
    }
    
    // MARK: - Private Methods
    
    private func uploadSingleFile(_ file: GalleryUploadRequest.UploadFile, at index: Int, partyId: UUID) async {
        let progressId = uploadProgress[index].id
        
        // Update status to uploading
        updateUploadProgress(id: progressId, status: .uploading, progress: 0.0)
        
        do {
            // Create unique filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let sanitizedFilename = file.filename.replacingOccurrences(of: "[^a-zA-Z0-9.-]", with: "_", options: .regularExpression)
            let fileName = "\(timestamp)_\(sanitizedFilename)"
            let filePath = "\(partyId)/\(fileName)"
            
            // Upload to storage
            updateUploadProgress(id: progressId, status: .uploading, progress: 0.3)
            
            let uploadData = try await supabase.storage
                .from("gallery")
                .upload(
                    path: filePath,
                    file: file.data,
                    options: FileOptions(
                        cacheControl: "3600",
                        contentType: file.mimeType
                    )
                )
            
            updateUploadProgress(id: progressId, status: .uploading, progress: 0.7)
            
            // Create database entry
            guard let userId = await getCurrentUserId() else {
                throw GalleryError.userNotAuthenticated
            }
            
            let galleryItem = GalleryItem(
                id: UUID(),
                partyId: partyId,
                userId: userId,
                fileUrl: filePath,
                fileType: file.fileType,
                fileSize: file.data.count,
                filename: file.filename,
                createdAt: Date(),
                updatedAt: Date(),
                user: nil
            )
            
            try await supabase
                .from("gallery_items")
                .insert(galleryItem)
                .execute()
            
            updateUploadProgress(id: progressId, status: .completed, progress: 1.0)
            
        } catch {
            updateUploadProgress(id: progressId, status: .failed, progress: 0.0, error: error.localizedDescription)
        }
    }
    
    private func generateSignedUrls(for items: [GalleryItem]) async -> [GalleryItem] {
        return await withTaskGroup(of: (Int, GalleryItem).self, returning: [GalleryItem].self) { group in
            for (index, item) in items.enumerated() {
                group.addTask {
                    let signedUrl = await self.getSignedUrl(for: item.fileUrl)
                    var updatedItem = item
                    updatedItem.signedUrl = signedUrl
                    return (index, updatedItem)
                }
            }
            
            var results: [(Int, GalleryItem)] = []
            for await result in group {
                results.append(result)
            }
            
            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }
    }
    
    private func getSignedUrl(for filePath: String) async -> String? {
        do {
            print("🔗 Generating signed URL for: \(filePath)")
            let response = try await supabase.storage
                .from("gallery")
                .createSignedURL(path: filePath, expiresIn: 3600)
            
            print("🔗 Generated signed URL: \(response.absoluteString)")
            return response.absoluteString
        } catch {
            print("❌ Failed to generate signed URL for \(filePath): \(error)")
            return nil
        }
    }
    
    private func getCurrentUserId() async -> UUID? {
        do {
            let session = try await supabase.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }
    
    private func updateUploadProgress(id: String, status: UploadProgress.UploadStatus, progress: Double, error: String? = nil) {
        if let index = uploadProgress.firstIndex(where: { $0.id == id }) {
            uploadProgress[index] = UploadProgress(
                id: id,
                filename: uploadProgress[index].filename,
                progress: progress,
                status: status,
                error: error
            )
        }
    }
    
}

// MARK: - Error Types
enum GalleryError: LocalizedError {
    case userNotAuthenticated
    case uploadFailed
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .uploadFailed:
            return "Upload failed"
        case .networkError:
            return "Network error"
        }
    }
}

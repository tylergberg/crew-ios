import Foundation
import Supabase

class VideoUploadService: ObservableObject {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Upload Video
    func uploadVideo(
        videoData: Data,
        gameId: String,
        questionId: String,
        filename: String
    ) async throws -> String {
        let storagePath = "\(gameId)/\(questionId)/\(filename)"
        
        // Upload to Supabase Storage
        let _ = try await supabase.storage
            .from("game-videos")
            .upload(
                path: storagePath,
                file: videoData,
                options: FileOptions(contentType: "video/mp4")
            )
        
        // Get public URL
        let publicURL = try supabase.storage
            .from("game-videos")
            .getPublicURL(path: storagePath)
        
        return publicURL.absoluteString
    }
    
    // MARK: - Update Game Videos
    func updateGameVideos(
        gameId: String,
        newVideo: GameVideo
    ) async throws {
        // First, get the current game to update its videos
        let response: [PartyGame] = try await supabase
            .from("party_games")
            .select()
            .eq("id", value: gameId)
            .execute()
            .value
        
        guard let currentGame = response.first else {
            throw VideoUploadError.gameNotFound
        }
        
        // Parse existing videos
        var currentVideos = currentGame.videos
        
        // Add new video
        currentVideos[newVideo.questionId] = newVideo
        
        // Convert videos back to JSON string
        let videosJSON = try JSONSerialization.data(withJSONObject: currentVideos.mapKeys { $0 })
        let videosString = String(data: videosJSON, encoding: .utf8) ?? "{}"
        
        // Update the game in the database
        try await supabase
            .from("party_games")
            .update([
                "videos": videosString,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: gameId)
            .execute()
    }
    
    // MARK: - Delete Video
    func deleteVideo(
        gameId: String,
        questionId: String,
        filename: String
    ) async throws {
        // Delete from storage
        try await supabase.storage
            .from("game-videos")
            .remove(paths: ["\(gameId)/\(questionId)/\(filename)"])
        
        // Remove from game videos and update database
        let response: [PartyGame] = try await supabase
            .from("party_games")
            .select()
            .eq("id", value: gameId)
            .execute()
            .value
        
        guard let currentGame = response.first else {
            throw VideoUploadError.gameNotFound
        }
        
        var currentVideos = currentGame.videos
        currentVideos.removeValue(forKey: questionId)
        
        let videosJSON = try JSONSerialization.data(withJSONObject: currentVideos.mapKeys { $0 })
        let videosString = String(data: videosJSON, encoding: .utf8) ?? "{}"
        
        try await supabase
            .from("party_games")
            .update([
                "videos": videosString,
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ])
            .eq("id", value: gameId)
            .execute()
    }
}

// MARK: - Error Types
enum VideoUploadError: Error, LocalizedError {
    case gameNotFound
    case uploadFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .gameNotFound:
            return "Game not found"
        case .uploadFailed:
            return "Video upload failed"
        case .invalidData:
            return "Invalid video data"
        }
    }
}

// MARK: - Helper Extensions
extension Dictionary {
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        var result: [T: Value] = [:]
        for (key, value) in self {
            result[transform(key)] = value
        }
        return result
    }
}

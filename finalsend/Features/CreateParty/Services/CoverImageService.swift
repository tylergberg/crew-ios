import Foundation
import UIKit
import Supabase

protocol CoverImageServiceType {
    func uploadImage(_ image: UIImage) async throws -> String
    func searchUnsplashImages(query: String) async throws -> [UnsplashImage]
}

class CoverImageService: CoverImageServiceType {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    /// Uploads an image to Supabase Storage and returns the public URL
    func uploadImage(_ image: UIImage) async throws -> String {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw CoverImageError.invalidImageData
        }
        
        // Create unique filename
        let fileName = "\(UUID().uuidString)_\(Date().timeIntervalSince1970).jpg"
        let filePath = fileName
        
        do {
            // Upload the file to Supabase Storage using the new method
            let uploadResult = try await client.storage
                .from("party-covers")
                .upload(filePath, data: imageData, options: FileOptions(
                    cacheControl: "3600",
                    upsert: false
                ))
            
            // Get the public URL
            let publicURL = try client.storage
                .from("party-covers")
                .getPublicURL(path: filePath)
            
            return publicURL.absoluteString
            
        } catch {
            throw CoverImageError.uploadFailed(error.localizedDescription)
        }
    }
    
    /// Searches Unsplash for images
    func searchUnsplashImages(query: String) async throws -> [UnsplashImage] {
        guard !query.isEmpty else { return [] }
        
        let urlString = "https://api.unsplash.com/search/photos?query=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&per_page=30"
        
        guard let url = URL(string: urlString) else {
            throw CoverImageError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Client-ID q6qSuff-Lh7XXcf7szsfUphI0b9rvsyl4YRctxz-0uE", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw CoverImageError.networkError("Failed to fetch images")
        }
        
        let searchResponse = try JSONDecoder().decode(UnsplashSearchResponse.self, from: data)
        return searchResponse.results
    }
}

// MARK: - Models

struct UnsplashImage: Codable, Identifiable {
    let id: String
    let urls: UnsplashImageURLs
    let user: UnsplashUser
    let altDescription: String?
    
    enum CodingKeys: String, CodingKey {
        case id, urls, user
        case altDescription = "alt_description"
    }
}

struct UnsplashImageURLs: Codable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct UnsplashUser: Codable {
    let name: String
    let username: String
}

struct UnsplashSearchResponse: Codable {
    let results: [UnsplashImage]
}

// MARK: - Errors

enum CoverImageError: Error, LocalizedError {
    case invalidImageData
    case uploadFailed(String)
    case networkError(String)
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .invalidImageData:
            return "Invalid image data"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .invalidURL:
            return "Invalid URL"
        }
    }
}

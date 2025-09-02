import UIKit
import Supabase
import Foundation

class AvatarUploadService {
    static let shared = AvatarUploadService()

    private let client: SupabaseClient

    private init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }

    /// Uploads the provided UIImage to the `avatars` bucket at path "{userId}/avatar.jpg",
    /// updates the user's `profiles.avatar_url`, and returns the public URL.
    @discardableResult
    func upload(image: UIImage, for userId: String) async throws -> URL {
        let resizedImage = image.resizedMaintainingAspect(maxDimension: 1024)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.85) else {
            throw AvatarUploadServiceError.imageEncodingFailed
        }

        // Use a unique path per upload to avoid CDN/browser cache collisions
        let uniqueId = UUID().uuidString.lowercased()
        // Ensure userId is lowercase to match auth.uid() format
        let path = "\(userId.lowercased())/avatar_\(uniqueId).jpg"

        // Upload (upsert)
        _ = try await client.storage
            .from("avatars")
            .upload(
                path: path,
                file: imageData,
                options: FileOptions(
                    cacheControl: "3600",
                    contentType: "image/jpeg",
                    upsert: true
                )
            )

        // Get public URL
        let publicURL = try client.storage
            .from("avatars")
            .getPublicURL(path: path)

        // Update profiles.avatar_url
        struct UpdatePayload: Encodable { let avatar_url: String }
        let payload = UpdatePayload(avatar_url: publicURL.absoluteString)

        _ = try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: userId)
            .execute()

        // Broadcast notifications so listeners can refresh
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .avatarUpdated,
                object: nil,
                userInfo: ["userId": userId, "avatar_url": publicURL.absoluteString]
            )
            NotificationCenter.default.post(
                name: .profileUpdated,
                object: nil,
                userInfo: ["userId": userId]
            )
        }

        return publicURL
    }

    /// Removes the avatar by clearing the DB field and attempting to delete from storage.
    func removeAvatar(for userId: String) async throws {
        // Clear DB field
        struct UpdatePayload: Encodable { let avatar_url: String? }
        let payload = UpdatePayload(avatar_url: nil)

        _ = try await client
            .from("profiles")
            .update(payload)
            .eq("id", value: userId)
            .execute()

        // Best-effort delete from storage
        let path = "\(userId.lowercased())/avatar.jpg"
        do {
            _ = try await client.storage
                .from("avatars")
                .remove(paths: [path])
        } catch {
            // Non-fatal
            print("[AvatarUploadService] Storage delete failed: \(error)")
        }

        // Broadcast notifications
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: .avatarUpdated,
                object: nil,
                userInfo: ["userId": userId, "avatar_url": NSNull()]
            )
            NotificationCenter.default.post(
                name: .profileUpdated,
                object: nil,
                userInfo: ["userId": userId]
            )
        }
    }
}

enum AvatarUploadServiceError: Error {
    case imageEncodingFailed
}

private extension UIImage {
    func resizedMaintainingAspect(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        // Force SDR to avoid HDR conversion warnings in simulator/devices
        if #available(iOS 12.0, *) {
            format.preferredRange = .standard
        }
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}



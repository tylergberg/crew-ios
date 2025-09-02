import Foundation

/// Maintains a per-user cache-busting version for avatar URLs and bumps on avatar updates.
class AvatarURLVersioner {
    static let shared = AvatarURLVersioner()

    private var userIdToVersion: [String: Int] = [:]
    private let queue = DispatchQueue(label: "avatar.url.versioner.queue")

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarUpdated(_:)), name: .avatarUpdated, object: nil)
    }

    func bump(userId: String) {
        queue.sync {
            let current = userIdToVersion[userId] ?? 0
            userIdToVersion[userId] = current + 1
        }
    }

    func version(for userId: String?) -> Int {
        guard let userId = userId else { return 0 }
        return queue.sync { userIdToVersion[userId] ?? 0 }
    }

    func versionedURLString(baseURL: String?, userId: String?) -> String? {
        guard let baseURL = baseURL, !baseURL.isEmpty else { return baseURL }
        let v = version(for: userId)
        if v == 0 { return baseURL }
        // Preserve existing query if any
        if baseURL.contains("?") {
            return baseURL + "&v=\(v)"
        } else {
            return baseURL + "?v=\(v)"
        }
    }

    @objc private func handleAvatarUpdated(_ notification: Notification) {
        guard let userId = notification.userInfo?["userId"] as? String else { return }
        bump(userId: userId)
    }
}



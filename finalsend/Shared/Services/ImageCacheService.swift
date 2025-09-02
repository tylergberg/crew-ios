import SwiftUI
import Foundation

class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()
    
    private let cache = NSCache<NSString, UIImage>()
    private var loadingTasks: [String: Task<UIImage?, Error>] = [:]
    private let queue = DispatchQueue(label: "ImageCacheService", attributes: .concurrent)
    
    private init() {
        cache.countLimit = 100 // Limit cache to 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit
    }
    
    func loadImage(from urlString: String) async -> UIImage? {
        guard let url = URL(string: urlString) else { return nil }
        
        let key = NSString(string: urlString)
        
        // Check if image is already cached
        if let cachedImage = cache.object(forKey: key) {
            return cachedImage
        }
        
        // Check if there's already a loading task for this URL
        if let existingTask = queue.sync(execute: { loadingTasks[urlString] }) {
            return try? await existingTask.value
        }
        
        // Create new loading task
        let task = Task<UIImage?, Error> {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    print("🖼️ ImageCache: Failed to create image from data for \(urlString)")
                    return nil
                }
                
                // Cache the image
                self.cache.setObject(image, forKey: key)
                
                return image
            } catch {
                print("🖼️ ImageCache: Failed to load image for \(urlString): \(error)")
                return nil
            }
        }
        
        // Store the task
        queue.async(flags: .barrier) {
            self.loadingTasks[urlString] = task
        }
        
        // Execute and clean up
        let result = try? await task.value
        queue.async(flags: .barrier) {
            self.loadingTasks.removeValue(forKey: urlString)
        }
        
        return result
    }
    
    func clearCache() {
        cache.removeAllObjects()
        print("🖼️ ImageCache: Cache cleared")
    }
    
    func removeImage(for urlString: String) {
        let key = NSString(string: urlString)
        cache.removeObject(forKey: key)
        print("🖼️ ImageCache: Removed image for \(urlString)")
    }
}

// MARK: - Cached AsyncImage View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: String?
    let content: (Image) -> Content
    let placeholder: () -> Placeholder
    
    @StateObject private var imageCache = ImageCacheService.shared
    @State private var image: UIImage?
    @State private var isLoading = false
    
    init(
        url: String?,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.url = url
        self.content = content
        self.placeholder = placeholder
    }
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
            }
        }
        .onAppear {
            loadImage()
        }
        .onChange(of: url) { _ in
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = url, !url.isEmpty else {
            image = nil
            isLoading = false
            return
        }
        
        isLoading = true
        
        Task {
            let loadedImage = await imageCache.loadImage(from: url)
            await MainActor.run {
                self.image = loadedImage
                self.isLoading = false
            }
        }
    }
}

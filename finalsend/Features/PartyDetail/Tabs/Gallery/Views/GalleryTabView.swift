import SwiftUI

struct GalleryTabView: View {
    let userRole: UserRole
    let partyId: UUID
    
    @StateObject private var galleryService = GalleryService.shared
    @State private var showingPhotoPicker = false
    @State private var selectedItem: GalleryItem?
    @State private var showingFullScreen = false
    @State private var isLoadingImage = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                if galleryService.isLoading && galleryService.galleryItems.isEmpty {
                    LoadingView()
                } else if galleryService.galleryItems.isEmpty {
                    EmptyGalleryView()
                } else {
                    GalleryGridView(
                        items: galleryService.galleryItems,
                        onItemTap: { item in
                            Task {
                                await loadImageAndPresent(item: item)
                            }
                        },
                        onDeleteItem: { item in
                            Task {
                                await galleryService.deleteItem(item)
                            }
                        }
                    )
                }
                
                // Upload progress overlay
                if galleryService.isUploading {
                    UploadProgressOverlay(progress: galleryService.uploadProgress)
                }
                
                // Image loading overlay
                if isLoadingImage {
                    ImageLoadingOverlay()
                }
            }
            .navigationTitle("Gallery")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingPhotoPicker = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.primary)
                    }
                }
            }
            .refreshable {
                await galleryService.fetchGalleryItems(for: partyId)
            }
            .sheet(isPresented: $showingPhotoPicker) {
                PhotoPickerView(partyId: partyId)
            }
            .fullScreenCover(isPresented: $showingFullScreen) {
                if let item = selectedItem {
                    InstagramStyleGalleryView(
                        items: galleryService.galleryItems,
                        selectedItem: item,
                        onLoadMore: {
                            await galleryService.loadMoreGalleryItems(for: partyId)
                        }
                    )
                }
            }
            .onAppear {
                Task {
                    await galleryService.fetchGalleryItems(for: partyId)
                    galleryService.startRealtimeUpdates(for: partyId)
                }
            }
            .onDisappear {
                galleryService.stopRealtimeUpdates()
            }
        }
    }
    
    // MARK: - Image Loading Function
    private func loadImageAndPresent(item: GalleryItem) async {
        await MainActor.run {
            isLoadingImage = true
        }
        
        // Wait for the image to load by creating a preview
        let imageUrl = item.signedUrl ?? item.fileUrl
        
        if let url = URL(string: imageUrl) {
            // Create a simple image loader to ensure the image is ready
            let imageLoader = ImageLoader()
            let _ = await imageLoader.loadImage(from: url)
        }
        
        // Minimal delay for smooth transition
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        await MainActor.run {
            selectedItem = item
            showingFullScreen = true
            isLoadingImage = false
        }
    }
}

// MARK: - Image Loader
class ImageLoader: ObservableObject {
    func loadImage(from url: URL) async -> UIImage? {
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            return UIImage(data: data)
        } catch {
            print("Failed to load image: \(error)")
            return nil
        }
    }
}

// MARK: - Image Loading Overlay
struct ImageLoadingOverlay: View {
    @State private var isSpinning = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.black)
                    .rotationEffect(.degrees(isSpinning ? 360 : 0))
                    .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isSpinning)
                    .onAppear {
                        isSpinning = true
                    }
            }
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading gallery...")
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Empty Gallery View
struct EmptyGalleryView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.on.rectangle")
                .font(.system(size: 64))
                .foregroundColor(.secondary)
            
            VStack(spacing: 8) {
                Text("No photos yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Be the first to share a memory from your trip!")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
        }
    }
}

// MARK: - Upload Progress Overlay
struct UploadProgressOverlay: View {
    let progress: [UploadProgress]
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)
                    Text("Uploading \(progress.count) file\(progress.count == 1 ? "" : "s")")
                        .font(.headline)
                    Spacer()
                }
                
                ForEach(progress) { item in
                    UploadProgressRow(progress: item)
                }
            }
            .padding()
            .background(.regularMaterial)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }
}

// MARK: - Upload Progress Row
struct UploadProgressRow: View {
    let progress: UploadProgress
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(progress.filename)
                    .font(.caption)
                    .lineLimit(1)
                
                Spacer()
                
                Text(progress.status.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(statusColor)
            }
            
            ProgressView(value: progress.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: statusColor))
        }
    }
    
    private var statusColor: Color {
        switch progress.status {
        case .pending:
            return .secondary
        case .uploading:
            return .blue
        case .completed:
            return .green
        case .failed:
            return .red
        }
    }
}

#Preview {
    GalleryTabView(userRole: .attendee, partyId: UUID())
}


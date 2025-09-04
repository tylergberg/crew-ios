import SwiftUI

struct InstagramStyleGalleryView: View {
    let items: [GalleryItem]
    let selectedItem: GalleryItem
    let onLoadMore: () async -> Void
    
    @State private var currentIndex: Int
    @State private var showingComments = false
    @State private var selectedItemForComments: GalleryItem?
    @State private var isViewReady = false
    @Environment(\.dismiss) private var dismiss
    
    init(items: [GalleryItem], selectedItem: GalleryItem, onLoadMore: @escaping () async -> Void) {
        self.items = items
        self.selectedItem = selectedItem
        self.onLoadMore = onLoadMore
        self._currentIndex = State(initialValue: items.firstIndex(where: { $0.id == selectedItem.id }) ?? 0)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 20) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            InstagramGalleryItemView(
                                item: item,
                                onCommentTap: {
                                    selectedItemForComments = item
                                    showingComments = true
                                },
                                onLoadMore: index == items.count - 3 ? onLoadMore : nil
                            )
                            .id("item-\(index)") // More specific ID
                        }
                    }
                    .padding(.top, 8) // Small padding to prevent content from being hidden under nav bar
                }
                .onAppear {
                    print("🎯 InstagramStyleGalleryView appeared")
                    print("🎯 Current index: \(currentIndex)")
                    print("🎯 Selected item ID: \(selectedItem.id)")
                    print("🎯 Total items: \(items.count)")
                    
                    // Single, immediate scroll to the selected item
                    DispatchQueue.main.async {
                        print("🎯 Scrolling to item-\(currentIndex)")
                        proxy.scrollTo("item-\(currentIndex)", anchor: .top)
                    }
                }
            }
            
            // Top navigation bar
            VStack(spacing: 0) {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                    }
                    
                    Spacer()
                    
                    Text("Gallery")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Placeholder for symmetry
                    Color.clear
                        .frame(width: 44, height: 44)
                }
                .padding(.horizontal, 20)
                .frame(height: 44)
                .background(Color.black)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .task {
            // Ensure proper scroll positioning after view loads
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
            // This will be handled by the ScrollViewReader
        }
        .sheet(isPresented: $showingComments) {
            if let item = selectedItemForComments {
                CommentsView(item: item)
            }
        }
    }
}

// MARK: - Instagram Gallery Item View
struct InstagramGalleryItemView: View {
    let item: GalleryItem
    let onCommentTap: () -> Void
    let onLoadMore: (() async -> Void)?
    
    @StateObject private var galleryService = GalleryService.shared
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var commentCount = 0
    @State private var showingFullImage = false
    @State private var isLoadingStats = true
    
    var body: some View {
        VStack(spacing: 0) {
            // User Header (like Instagram)
            HStack(spacing: 12) {
                // Profile picture
                AsyncImage(url: URL(string: item.user?.avatarUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .overlay(
                            Image(systemName: "person.fill")
                                .foregroundColor(.white)
                                .font(.system(size: 16))
                        )
                }
                .frame(width: 32, height: 32)
                .clipShape(Circle())
                
                // Username
                Text(item.user?.displayName ?? "Unknown User")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                
                Spacer()
                
                // More options button
                Button(action: {
                    // More options
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8) // Padding to separate from nav bar
            .padding(.bottom, 8)
            
            // Media Section
            ZStack {
                if item.isImage {
                    AsyncImage(url: URL(string: item.signedUrl ?? item.fileUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                    } placeholder: {
                        ZStack {
                            Color.black
                            VStack(spacing: 12) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                    .foregroundColor(.white)
                                Text("Loading...")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        }
                        .frame(height: 300)
                    }
                } else {
                    // Video placeholder
                    ZStack {
                        Color.black
                        VStack(spacing: 12) {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            Text("Video")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                    .frame(height: 300)
                }
                
                // Tap to view full screen
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        showingFullImage = true
                    }
            }
            
            // Interaction Bar
            HStack(spacing: 20) {
                Button(action: {
                    withAnimation(.spring()) {
                        isLiked.toggle()
                        likeCount += isLiked ? 1 : -1
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(isLiked ? .red : .white)
                }
                
                Button(action: onCommentTap) {
                    Image(systemName: "bubble.left")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Button(action: {
                    // Share functionality
                }) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                Button(action: {
                    // Bookmark functionality
                }) {
                    Image(systemName: "bookmark")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            
            // Likes and Comments
            VStack(alignment: .leading, spacing: 8) {
                if isLoadingStats {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                        Text("Loading...")
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                } else {
                    if likeCount > 0 {
                        Text("\(likeCount) like\(likeCount == 1 ? "" : "s")")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    
                    // Comments preview
                    if commentCount > 0 {
                        Button(action: onCommentTap) {
                            Text("View all \(commentCount) comment\(commentCount == 1 ? "" : "s")")
                                .font(.system(size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    
                    // Timestamp
                    Text(formatDate(item.createdAt))
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color.black)
        .cornerRadius(0)
        .onAppear {
            // Load initial data
            loadItemData()
            
            // Trigger load more if this is near the end
            if let onLoadMore = onLoadMore {
                Task {
                    await onLoadMore()
                }
            }
        }
        .fullScreenCover(isPresented: $showingFullImage) {
            InstagramFullScreenImageView(item: item)
        }
    }
    
    private func loadItemData() {
        Task {
            let stats = await galleryService.getItemStats(for: item)
            await MainActor.run {
                likeCount = stats.likesCount
                commentCount = stats.commentsCount
                isLiked = stats.isLikedByCurrentUser
                isLoadingStats = false
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

// MARK: - Instagram Full Screen Image View
struct InstagramFullScreenImageView: View {
    let item: GalleryItem
    @Environment(\.dismiss) private var dismiss
    @State private var dragOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if item.isImage {
                AsyncImage(url: URL(string: item.signedUrl ?? item.fileUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .offset(y: dragOffset.height)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    let horizontalMovement = abs(value.translation.width)
                                    let verticalMovement = abs(value.translation.height)
                                    
                                    if verticalMovement > horizontalMovement {
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    let horizontalMovement = abs(value.translation.width)
                                    let verticalMovement = abs(value.translation.height)
                                    
                                    if verticalMovement > horizontalMovement && 
                                       value.translation.height > 100 {
                                        dismiss()
                                    } else {
                                        withAnimation(.spring()) {
                                            dragOffset = .zero
                                        }
                                    }
                                }
                        )
                } placeholder: {
                    ZStack {
                        Color.black
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .foregroundColor(.white)
                            Text("Loading...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                }
            }
            
            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
}

#Preview {
    let sampleItems = [
        GalleryItem(
            id: UUID(),
            partyId: UUID(),
            userId: UUID(),
            fileUrl: "https://example.com/photo1.jpg",
            fileType: "image",
            fileSize: 1024000,
            filename: "photo1.jpg",
            createdAt: Date(),
            updatedAt: Date(),
            user: GalleryUser(id: UUID(), fullName: "John Doe", avatarUrl: nil)
        )
    ]
    
    InstagramStyleGalleryView(
        items: sampleItems,
        selectedItem: sampleItems[0],
        onLoadMore: {}
    )
}

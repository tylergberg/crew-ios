import SwiftUI

struct GalleryFeedView: View {
    let items: [GalleryItem]
    let selectedItem: GalleryItem
    let onLoadMore: () async -> Void
    
    @State private var currentIndex: Int
    @State private var showingComments = false
    @State private var selectedItemForComments: GalleryItem?
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
                    LazyVStack(spacing: 0) {
                        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                            GalleryFeedItemView(
                                item: item,
                                onCommentTap: {
                                    selectedItemForComments = item
                                    showingComments = true
                                },
                                onLoadMore: index == items.count - 3 ? onLoadMore : nil
                            )
                            .id(index)
                        }
                    }
                }
                .onAppear {
                    // Scroll to selected item
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            proxy.scrollTo(currentIndex, anchor: .center)
                        }
                    }
                }
            }
            
            // Top navigation
            VStack {
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
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
                .padding(.top, 10)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingComments) {
            if let item = selectedItemForComments {
                CommentsView(item: item)
            }
        }
    }
}

// MARK: - Gallery Feed Item View
struct GalleryFeedItemView: View {
    let item: GalleryItem
    let onCommentTap: () -> Void
    let onLoadMore: (() async -> Void)?
    
    @State private var isLiked = false
    @State private var likeCount = 0
    @State private var commentCount = 0
    @State private var showingFullImage = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Media Section
            ZStack {
                if item.isImage {
                    AsyncImage(url: URL(string: item.signedUrl ?? item.fileUrl)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 300)
                            .overlay(
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .scaleEffect(1.2)
                                        .foregroundColor(.white)
                                    Text("Loading...")
                                        .foregroundColor(.white)
                                        .font(.caption)
                                }
                            )
                    }
                } else {
                    // Video placeholder
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 300)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 48))
                                    .foregroundColor(.white)
                                Text("Video")
                                    .foregroundColor(.white)
                                    .font(.caption)
                            }
                        )
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
                if likeCount > 0 {
                    Text("\(likeCount) like\(likeCount == 1 ? "" : "s")")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                // Caption/Description
                HStack(alignment: .top, spacing: 8) {
                    Text(item.user?.displayName ?? "Unknown User")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text("Shared a memory from the trip")
                        .font(.system(size: 14))
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
                Text(item.createdAt, style: .relative)
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
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
            FullScreenImageView(item: item)
        }
    }
    
    private func loadItemData() {
        // TODO: Load likes and comments count from service
        likeCount = Int.random(in: 0...50) // Placeholder
        commentCount = Int.random(in: 0...10) // Placeholder
    }
}

// MARK: - Full Screen Image View
struct FullScreenImageView: View {
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
    
    GalleryFeedView(
        items: sampleItems,
        selectedItem: sampleItems[0],
        onLoadMore: {}
    )
}

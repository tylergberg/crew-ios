import SwiftUI

struct GalleryDetailView: View {
    let items: [GalleryItem]
    let selectedItem: GalleryItem
    
    @State private var currentIndex: Int
    @State private var showingControls = true
    @State private var showingComments = false
    @Environment(\.dismiss) private var dismiss
    
    init(items: [GalleryItem], selectedItem: GalleryItem) {
        self.items = items
        self.selectedItem = selectedItem
        self._currentIndex = State(initialValue: items.firstIndex(where: { $0.id == selectedItem.id }) ?? 0)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main photo viewer with swipe navigation
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    PhotoDetailView(item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            
            // Top navigation bar (iOS Photos style)
            if showingControls {
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
                        
                        Text("\(currentIndex + 1) of \(items.count)")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Button(action: {
                            showingComments = true
                        }) {
                            Image(systemName: "bubble.left")
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
                .transition(.opacity)
            }
            
            // Bottom thumbnail strip
            if showingControls && items.count > 1 {
                VStack {
                    Spacer()
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                ThumbnailButton(
                                    item: item,
                                    isSelected: index == currentIndex
                                ) {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        currentIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 20)
                }
                .transition(.opacity)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingComments) {
            CommentsView(item: items[currentIndex])
        }
    }
    
}

// MARK: - Photo Detail View
struct PhotoDetailView: View {
    let item: GalleryItem
    
    @State private var dragOffset: CGSize = .zero
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if item.isImage {
                let imageUrl = item.signedUrl ?? item.fileUrl
                
                if let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .offset(y: dragOffset.height)
                        .gesture(
                            // Simple drag gesture for swipe down to dismiss
                            DragGesture()
                                .onChanged { value in
                                    // Only apply vertical drag for swipe down to dismiss
                                    let horizontalMovement = abs(value.translation.width)
                                    let verticalMovement = abs(value.translation.height)
                                    
                                    // Only apply vertical drag if it's more vertical than horizontal
                                    if verticalMovement > horizontalMovement {
                                        dragOffset = value.translation
                                    }
                                }
                                .onEnded { value in
                                    let horizontalMovement = abs(value.translation.width)
                                    let verticalMovement = abs(value.translation.height)
                                    
                                    // Only dismiss if it's clearly a vertical swipe down
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
                            Text("Loading photo...")
                                .foregroundColor(.white)
                                .font(.caption)
                        }
                    }
                }
                .onAppear {
                    let imageUrl = item.signedUrl ?? item.fileUrl
                    print("🖼️ PhotoDetailView appeared for item: \(item.filename)")
                    print("🖼️ File URL: \(item.fileUrl)")
                    print("🖼️ Signed URL: \(item.signedUrl ?? "nil")")
                    print("🖼️ Loading image from URL: \(imageUrl)")
                }
                } else {
                    // Invalid URL fallback
                    ZStack {
                        Color.black
                        VStack(spacing: 16) {
                            Image(systemName: "photo")
                                .font(.system(size: 48))
                                .foregroundColor(.white)
                            Text("Unable to load image")
                                .foregroundColor(.white)
                                .font(.caption)
                            Text("URL: \(imageUrl)")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.caption2)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
            } else {
                // Video placeholder
                ZStack {
                    Color.black
                    VStack(spacing: 16) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                        
                        Text("Video playback")
                            .foregroundColor(.white)
                            .font(.headline)
                        
                        Text("Video support coming soon")
                            .foregroundColor(.white.opacity(0.7))
                            .font(.caption)
                    }
                }
            }
        }
    }
}

// MARK: - Thumbnail Button
struct ThumbnailButton: View {
    let item: GalleryItem
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            AsyncImage(url: URL(string: item.signedUrl ?? item.fileUrl)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 60, height: 60)
            .clipped()
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
            .scaleEffect(isSelected ? 1.1 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
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
            user: nil
        ),
        GalleryItem(
            id: UUID(),
            partyId: UUID(),
            userId: UUID(),
            fileUrl: "https://example.com/photo2.jpg",
            fileType: "image",
            fileSize: 1024000,
            filename: "photo2.jpg",
            createdAt: Date(),
            updatedAt: Date(),
            user: nil
        )
    ]
    
    GalleryDetailView(
        items: sampleItems,
        selectedItem: sampleItems[0]
    )
}
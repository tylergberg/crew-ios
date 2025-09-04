import SwiftUI

struct GalleryModalView: View {
    let items: [GalleryItem]
    let selectedItem: GalleryItem
    let onDismiss: () -> Void
    
    @State private var currentIndex: Int
    @State private var dragOffset: CGSize = .zero
    @State private var showingControls = true
    @State private var controlsTimer: Timer?
    
    init(items: [GalleryItem], selectedItem: GalleryItem, onDismiss: @escaping () -> Void) {
        self.items = items
        self.selectedItem = selectedItem
        self.onDismiss = onDismiss
        self._currentIndex = State(initialValue: items.firstIndex(where: { $0.id == selectedItem.id }) ?? 0)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Main content
            TabView(selection: $currentIndex) {
                ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                    GalleryItemDetailView(item: item)
                        .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            .offset(y: dragOffset.height)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        dragOffset = value.translation
                    }
                    .onEnded { value in
                        if abs(value.translation.height) > 100 {
                            onDismiss()
                        } else {
                            withAnimation(.spring()) {
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .onTapGesture {
                toggleControls()
            }
            
            // Top controls
            if showingControls {
                VStack {
                    HStack {
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        Text("\(currentIndex + 1) of \(items.count)")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(20)
                    }
                    .padding()
                    
                    Spacer()
                }
                .transition(.opacity)
            }
            
            // Bottom controls
            if showingControls && items.count > 1 {
                VStack {
                    Spacer()
                    
                    // Thumbnail strip
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                                ThumbnailView(
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
        .onAppear {
            startControlsTimer()
        }
        .onDisappear {
            stopControlsTimer()
        }
    }
    
    private func toggleControls() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showingControls.toggle()
        }
        
        if showingControls {
            startControlsTimer()
        } else {
            stopControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        stopControlsTimer()
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showingControls = false
            }
        }
    }
    
    private func stopControlsTimer() {
        controlsTimer?.invalidate()
        controlsTimer = nil
    }
}

// MARK: - Gallery Item Detail View
struct GalleryItemDetailView: View {
    let item: GalleryItem
    
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        ZStack {
            if item.isImage {
                AsyncImage(url: URL(string: item.signedUrl ?? item.fileUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            SimultaneousGesture(
                                MagnificationGesture()
                                    .onChanged { value in
                                        let delta = value / lastScale
                                        lastScale = value
                                        scale = min(max(scale * delta, 1.0), 5.0)
                                    }
                                    .onEnded { _ in
                                        lastScale = 1.0
                                        if scale < 1.0 {
                                            withAnimation(.spring()) {
                                                scale = 1.0
                                                offset = .zero
                                            }
                                        }
                                    },
                                
                                DragGesture()
                                    .onChanged { value in
                                        if scale > 1.0 {
                                            offset = CGSize(
                                                width: lastOffset.width + value.translation.width,
                                                height: lastOffset.height + value.translation.height
                                            )
                                        }
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                            )
                        )
                } placeholder: {
                    ProgressView()
                        .scaleEffect(1.5)
                        .foregroundColor(.white)
                }
            } else {
                // Video player would go here
                VStack {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                    
                    Text("Video playback not implemented yet")
                        .foregroundColor(.white)
                        .font(.caption)
                }
            }
        }
        .onTapGesture(count: 2) {
            withAnimation(.spring()) {
                if scale > 1.0 {
                    scale = 1.0
                    offset = .zero
                    lastOffset = .zero
                } else {
                    scale = 2.0
                }
            }
        }
    }
}

// MARK: - Thumbnail View
struct ThumbnailView: View {
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
    
    GalleryModalView(
        items: sampleItems,
        selectedItem: sampleItems[0],
        onDismiss: {}
    )
}

import SwiftUI

struct GalleryGridView: View {
    let items: [GalleryItem]
    let onItemTap: (GalleryItem) -> Void
    let onDeleteItem: (GalleryItem) async -> Void
    
    @State private var selectedItem: GalleryItem?
    @State private var showingDeleteConfirmation = false
    
    private let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 2) {
                ForEach(items) { item in
                    GalleryItemView(
                        item: item,
                        onTap: {
                            onItemTap(item)
                        },
                        onDelete: {
                            selectedItem = item
                            showingDeleteConfirmation = true
                        }
                    )
                }
            }
            .padding(.horizontal, 2)
        }
        .confirmationDialog(
            "Delete Photo",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = selectedItem {
                    Task {
                        await onDeleteItem(item)
                    }
                }
            }
            Button("Cancel", role: .cancel) {
                selectedItem = nil
            }
        } message: {
            Text("Are you sure you want to delete this photo? This action cannot be undone.")
        }
    }
}

// MARK: - Gallery Item View
struct GalleryItemView: View {
    let item: GalleryItem
    let onTap: () -> Void
    let onDelete: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Image/Video
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
                        )
                }
                .frame(height: 120)
                .clipped()
                
                // Video indicator
                if item.isVideo {
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(8)
                        }
                    }
                }
                
                // Delete button (appears on long press)
                if isPressed {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .background(Color.red)
                                    .clipShape(Circle())
                            }
                            .padding(8)
                        }
                        Spacer()
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(
            minimumDuration: 0.5,
            maximumDistance: 10,
            pressing: { pressing in
                isPressed = pressing
            },
            perform: {}
        )
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
            fileUrl: "https://example.com/video1.mp4",
            fileType: "video",
            fileSize: 5120000,
            filename: "video1.mp4",
            createdAt: Date(),
            updatedAt: Date(),
            user: nil
        )
    ]
    
    GalleryGridView(
        items: sampleItems,
        onItemTap: { _ in },
        onDeleteItem: { _ in }
    )
}

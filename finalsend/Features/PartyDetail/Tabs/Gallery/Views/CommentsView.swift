import SwiftUI

struct CommentsView: View {
    let item: GalleryItem
    
    @StateObject private var galleryService = GalleryService.shared
    @State private var comments: [GalleryComment] = []
    @State private var newCommentText = ""
    @State private var isLoading = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Comments list
                if comments.isEmpty {
                    VStack(spacing: 16) {
                        Spacer()
                        Image(systemName: "bubble.left")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No comments yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Be the first to comment on this photo!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Spacer()
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(comments) { comment in
                                CommentRow(comment: comment)
                            }
                        }
                        .padding()
                    }
                }
                
                // Add comment section
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Add a comment...", text: $newCommentText, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(1...4)
                        
                        Button(action: addComment) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .blue)
                        }
                        .disabled(newCommentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                    }
                    .padding()
                }
                .background(Color(.systemBackground))
            }
            .navigationTitle("Comments")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadComments()
        }
    }
    
    private func loadComments() {
        Task {
            let fetchedComments = await galleryService.fetchComments(for: item)
            await MainActor.run {
                comments = fetchedComments
            }
        }
    }
    
    private func addComment() {
        let text = newCommentText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        
        isLoading = true
        
        Task {
            let success = await galleryService.addComment(text, to: item)
            
            await MainActor.run {
                isLoading = false
                if success {
                    newCommentText = ""
                    loadComments() // Reload comments
                }
            }
        }
    }
}

// MARK: - Comment Row
struct CommentRow: View {
    let comment: GalleryComment
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // User avatar
            AsyncImage(url: URL(string: comment.user?.avatarUrl ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .overlay(
                        Text(comment.user?.displayName.prefix(1).uppercased() ?? "?")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    )
            }
            .frame(width: 32, height: 32)
            .clipShape(Circle())
            
            // Comment content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(comment.user?.displayName ?? "Unknown User")
                        .font(.caption)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Text(comment.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(comment.text)
                    .font(.body)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview
#Preview {
    let sampleComment = GalleryComment(
        id: UUID(),
        galleryItemId: UUID(),
        userId: UUID(),
        text: "This is a sample comment about the photo!",
        createdAt: Date(),
        updatedAt: Date(),
        user: GalleryUser(
            id: UUID(),
            fullName: "John Doe",
            avatarUrl: nil
        )
    )
    
    CommentsView(item: GalleryItem(
        id: UUID(),
        partyId: UUID(),
        userId: UUID(),
        fileUrl: "https://example.com/photo.jpg",
        fileType: "image",
        fileSize: 1024000,
        filename: "photo.jpg",
        createdAt: Date(),
        updatedAt: Date(),
        user: nil
    ))
}

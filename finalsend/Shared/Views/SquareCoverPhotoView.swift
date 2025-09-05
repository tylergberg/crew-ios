import SwiftUI

struct SquareCoverPhotoView: View {
    let imageURL: String?
    let size: CGFloat
    let cornerRadius: CGFloat
    let placeholderIcon: String
    let placeholderText: String?
    
    @State private var versionTick: Int = 0
    
    init(
        imageURL: String?,
        size: CGFloat = 200,
        cornerRadius: CGFloat = 12,
        placeholderIcon: String = "photo",
        placeholderText: String? = nil
    ) {
        self.imageURL = imageURL
        self.size = size
        self.cornerRadius = cornerRadius
        self.placeholderIcon = placeholderIcon
        self.placeholderText = placeholderText
    }
    
    init(
        imageURL: String?,
        width: CGFloat,
        cornerRadius: CGFloat = 12,
        placeholderIcon: String = "photo",
        placeholderText: String? = nil
    ) {
        self.imageURL = imageURL
        self.size = width
        self.cornerRadius = cornerRadius
        self.placeholderIcon = placeholderIcon
        self.placeholderText = placeholderText
    }
    
    var body: some View {
        Group {
            if let versionedURL = versionedImageURL {
                AsyncImage(url: URL(string: versionedURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    placeholderView
                }
                .frame(width: size, height: size)
                .clipped()
                .cornerRadius(cornerRadius)
            } else {
                placeholderView
                    .frame(width: size, height: size)
                    .cornerRadius(cornerRadius)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .refreshPartyData)) { _ in
            // Increment version tick when party data is refreshed to force image reload
            versionTick &+= 1
        }
    }
    
    private var versionedImageURL: String? {
        guard let imageURL = imageURL, !imageURL.isEmpty else { return imageURL }
        
        // Add version parameter to force cache refresh
        let separator = imageURL.contains("?") ? "&" : "?"
        return "\(imageURL)\(separator)v=\(versionTick)"
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        VStack(spacing: 8) {
            Image(systemName: placeholderIcon)
                .font(.system(size: size * 0.2))
                .foregroundColor(.gray)
            
            if let placeholderText = placeholderText {
                Text(placeholderText)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(width: size, height: size)
        .background(Color.gray.opacity(0.1))
    }
}

#Preview {
    VStack(spacing: 20) {
        SquareCoverPhotoView(
            imageURL: nil,
            size: 200,
            placeholderText: "Add Cover Photo"
        )
        
        SquareCoverPhotoView(
            imageURL: "https://example.com/image.jpg",
            size: 150
        )
        
        SquareCoverPhotoView(
            imageURL: nil,
            size: 100,
            cornerRadius: 8,
            placeholderText: "No Photo"
        )
    }
    .padding()
}

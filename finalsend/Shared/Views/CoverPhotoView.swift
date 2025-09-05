import SwiftUI

struct CoverPhotoView: View {
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholderIcon: String
    let placeholderText: String?
    
    @State private var versionTick: Int = 0
    
    init(
        imageURL: String?,
        width: CGFloat,
        height: CGFloat = 200,
        cornerRadius: CGFloat = 12,
        placeholderIcon: String = "photo",
        placeholderText: String? = nil
    ) {
        self.imageURL = imageURL
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.placeholderIcon = placeholderIcon
        self.placeholderText = placeholderText
    }
    
    var body: some View {
        CachedAsyncImage(url: versionedImageURL) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipped()
                .cornerRadius(cornerRadius)
        } placeholder: {
            placeholderView
                .frame(width: width, height: height)
                .cornerRadius(cornerRadius)
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
                .font(.system(size: 32))
                .foregroundColor(.secondary)
            
            if let placeholderText = placeholderText {
                Text(placeholderText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6))
    }
}




import SwiftUI

struct CoverPhotoView: View {
    let imageURL: String?
    let width: CGFloat
    let height: CGFloat
    let cornerRadius: CGFloat
    let placeholderIcon: String
    let placeholderText: String?
    
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
        CachedAsyncImage(url: imageURL) { image in
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




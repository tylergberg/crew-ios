import SwiftUI

struct VendorCardView: View {
    let vendor: Vendor

    private let cardWidth: CGFloat = 200

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Rectangle()
                    .fill(Color(.systemGray6))
                if let imageUrl = vendor.imageUrl, let url = URL(string: imageUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .clipped()
                } else {
                    Image(systemName: "photo")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: cardWidth, height: cardWidth)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(vendor.name)
                .font(.headline)
                .lineLimit(1)

            HStack(spacing: 6) {
                if let rating = vendor.rating {
                    Image(systemName: "star.fill").foregroundColor(.yellow)
                    Text(String(describing: rating))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                if let price = vendor.priceRange, !price.isEmpty {
                    Text(price)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .frame(height: 18)
        }
        .frame(width: cardWidth)
    }
}

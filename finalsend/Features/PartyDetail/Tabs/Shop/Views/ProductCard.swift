import SwiftUI

struct ProductCard: View {
    let product: Product
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                // Product Image
                ZStack {
                    Rectangle()
                        .fill(Color.white)
                        .aspectRatio(1, contentMode: .fit)
                    
                    Image(product.imageName)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .padding(20)
                        .onAppear {
                            print("Loading image: \(product.imageName)")
                        }
                }
                
                // Product Info Section (White Background)
                VStack(spacing: 8) {
                    Text(product.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                    
                    // Pricing
                    Text(product.displayPrice)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "#401B17"))
                        .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white) // Clean white background
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .offset(y: -0.5),
                    alignment: .top
                )
            }
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ProductCard(
        product: Product.sampleProducts[0],
        onTap: {}
    )
    .padding()
}

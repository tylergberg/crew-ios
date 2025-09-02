import SwiftUI

struct ShopProductsView: View {
    let userRole: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    
                    // Products Grid
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 16),
                        GridItem(.flexible(), spacing: 16)
                    ], spacing: 16) {
                        ForEach(Product.sampleProducts) { product in
                            ProductCard(product: product) {
                                // Handle product selection
                                print("Selected product: \(product.name)")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Contact Info
                    VStack(spacing: 8) {
                        Text("💬 Contact Us!")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Custom design uploads coming soon! For now, contact us on Instagram for high-quality custom merch at great prices.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.vertical)
                    .background(Color.gray.opacity(0.05))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Custom Merch")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Back") {
                    dismiss()
                }
            )
        }
    }
}

#Preview {
    NavigationView {
        ShopProductsView(userRole: "attendee")
    }
}

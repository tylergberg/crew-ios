import SwiftUI

struct ShopTabView: View {
    let userRole: String
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "tshirt")
                        .font(.system(size: 64))
                        .foregroundColor(.mint)
                    
                    Text("Shop")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Party merch")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Text("Coming soon...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Spacer()
            }
            .navigationTitle("Shop")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Back") {
                    // This will be handled by the fullScreenCover dismissal
                }
            )
        }
    }
}

#Preview {
    ShopTabView(userRole: "attendee")
}


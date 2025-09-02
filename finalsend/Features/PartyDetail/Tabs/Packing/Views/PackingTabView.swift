import SwiftUI

struct PackingTabView: View {
    let partyId: UUID
    let userRole: UserRole
    let currentUserId: UUID
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 64))
                        .foregroundColor(.orange)
                    
                    Text("Packing")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Manage packing lists")
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
            .navigationTitle("Packing")
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
    PackingTabView(
        partyId: UUID(),
        userRole: .attendee,
        currentUserId: UUID()
    )
}


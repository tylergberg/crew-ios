import SwiftUI

struct GalleryTabView: View {
    let userRole: UserRole
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "photo.on.rectangle")
                        .font(.system(size: 64))
                        .foregroundColor(.indigo)
                    
                    Text("Gallery")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Photos & memories")
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
            .navigationTitle("Gallery")
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
    GalleryTabView(userRole: .attendee)
}


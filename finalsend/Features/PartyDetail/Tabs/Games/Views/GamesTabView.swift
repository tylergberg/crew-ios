import SwiftUI

struct GamesTabView: View {
    let userRole: String
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller")
                        .font(.system(size: 64))
                        .foregroundColor(.pink)
                    
                    Text("Games")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Party activities and games")
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
            .navigationTitle("Games")
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
    GamesTabView(userRole: "attendee")
}


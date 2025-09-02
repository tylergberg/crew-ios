import SwiftUI

struct ExpensesTabView: View {
    let partyId: String
    let currentUserId: String
    let attendeesCount: Int
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "dollarsign.circle")
                        .font(.system(size: 64))
                        .foregroundColor(.blue)
                    
                    Text("Expenses")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Track and split party expenses")
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
            .navigationTitle("Expenses")
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
    ExpensesTabView(
        partyId: "test-party",
        currentUserId: "test-user",
        attendeesCount: 5
    )
}


import SwiftUI

struct TasksTabView: View {
    let userRole: UserRole
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.square")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("Tasks")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Manage party tasks")
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
            .navigationTitle("Tasks")
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
    TasksTabView(userRole: .attendee)
}


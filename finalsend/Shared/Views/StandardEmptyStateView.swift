import SwiftUI

struct StandardEmptyStateView: View {
    let icon: String
    let title: String
    let description: String
    let buttonTitle: String?
    let buttonAction: (() -> Void)?
    let userRole: UserRole?
    
    init(
        icon: String,
        title: String,
        description: String,
        buttonTitle: String? = nil,
        buttonAction: (() -> Void)? = nil,
        userRole: UserRole? = nil
    ) {
        self.icon = icon
        self.title = title
        self.description = description
        self.buttonTitle = buttonTitle
        self.buttonAction = buttonAction
        self.userRole = userRole
    }
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Icon
            Image(systemName: icon)
                .font(.system(size: 64, weight: .light))
                .foregroundColor(.secondary)
            
            // Title
            Text(title)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Description
            Text(description)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            // Action Button (if provided)
            if let buttonTitle = buttonTitle, let buttonAction = buttonAction {
                Button(action: buttonAction) {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text(buttonTitle)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.outlineBlack, lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 24)
    }
}

#Preview {
    VStack(spacing: 20) {
        StandardEmptyStateView(
            icon: "shippingbox",
            title: "No packing items yet",
            description: "Add your first item to get started!",
            buttonTitle: "Add First Item",
            buttonAction: { print("Add item tapped") }
        )
        
        StandardEmptyStateView(
            icon: "checklist",
            title: "No tasks yet",
            description: "Add tasks to keep track of planning responsibilities.",
            buttonTitle: "Add Your First Task",
            buttonAction: { print("Add task tapped") }
        )
        
        StandardEmptyStateView(
            icon: "photo.on.rectangle",
            title: "No photos or videos yet",
            description: "Be the first to share memories from your party!",
            buttonTitle: "Upload Photos & Videos",
            buttonAction: { print("Upload tapped") }
        )
    }
    .padding()
}

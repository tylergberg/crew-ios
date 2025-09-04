import SwiftUI

struct PackingItemRowView: View {
    let item: PackingItem
    let onTogglePacked: (Bool) -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingActions = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button(action: {
                onTogglePacked(!item.isPacked)
            }) {
                Image(systemName: item.isPacked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(item.isPacked ? .green : .gray)
            }
            .buttonStyle(PlainButtonStyle())
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .strikethrough(item.isPacked)
                    .foregroundColor(item.isPacked ? .secondary : .primary)
                
                if let description = item.description, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .strikethrough(item.isPacked)
                }
            }
            
            Spacer()
            
            // Packed badge
            if item.isPacked {
                Text("PACKED")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
            }
            
            // Actions button
            Button(action: {
                showingActions = true
            }) {
                Image(systemName: "ellipsis")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .actionSheet(isPresented: $showingActions) {
            ActionSheet(
                title: Text("Item Actions"),
                buttons: [
                    .default(Text("Edit")) {
                        onEdit()
                    },
                    .destructive(Text("Delete")) {
                        onDelete()
                    },
                    .cancel()
                ]
            )
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        PackingItemRowView(
            item: PackingItem(
                title: "Passport",
                description: "Don't forget your passport!",
                partyId: UUID(),
                createdBy: UUID()
            ),
            onTogglePacked: { _ in },
            onEdit: { },
            onDelete: { }
        )
        
        PackingItemRowView(
            item: PackingItem(
                title: "Sunscreen",
                description: "SPF 50+ recommended",
                partyId: UUID(),
                createdBy: UUID(),
                isPacked: true
            ),
            onTogglePacked: { _ in },
            onEdit: { },
            onDelete: { }
        )
    }
    .padding()
}

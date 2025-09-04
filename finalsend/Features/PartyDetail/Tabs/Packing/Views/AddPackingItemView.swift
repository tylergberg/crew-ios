import SwiftUI
import Supabase

struct AddPackingItemView: View {
    let partyId: UUID
    let userId: UUID
    let packingStore: PackingStore
    let editingItem: PackingItem?
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var isSubmitting = false
    
    var isEditing: Bool {
        editingItem != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Item Details")) {
                    TextField("Item name", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Save" : "Add") {
                        submitItem()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitting)
                }
            }
        }
        .onAppear {
            if let item = editingItem {
                title = item.title
                description = item.description ?? ""
            }
        }
    }
    
    private func submitItem() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalDescription = trimmedDescription.isEmpty ? nil : trimmedDescription
        
        isSubmitting = true
        
        Task {
            if let item = editingItem {
                await packingStore.updateItem(
                    itemId: item.id,
                    title: trimmedTitle,
                    description: finalDescription
                )
            } else {
                await packingStore.addItem(
                    partyId: partyId,
                    title: trimmedTitle,
                    description: finalDescription,
                    userId: userId
                )
            }
            
            await MainActor.run {
                isSubmitting = false
                dismiss()
            }
        }
    }
}

#Preview {
    AddPackingItemView(
        partyId: UUID(),
        userId: UUID(),
        packingStore: PackingStore(supabase: SupabaseClient(supabaseURL: URL(string: "https://example.com")!, supabaseKey: "key")),
        editingItem: nil
    )
}

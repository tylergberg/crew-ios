import SwiftUI

struct InlineAddPackingItemView: View {
    @Binding var title: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @FocusState private var isTitleFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Empty circle (like Reminders)
            Circle()
                .stroke(Color.secondary, lineWidth: 1.5)
                .frame(width: 20, height: 20)
            
            // Text field
            TextField("", text: $title)
                .focused($isTitleFocused)
                .onSubmit {
                    if !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onSave()
                    }
                }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        .onAppear {
            // Focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isTitleFocused = true
            }
        }
    }
}

#Preview {
    InlineAddPackingItemView(
        title: .constant(""),
        onSave: { },
        onCancel: { }
    )
    .padding()
}

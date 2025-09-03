import SwiftUI

struct AddCustomQuestionView: View {
    let onSave: (String, String) -> Void
    let onCancel: () -> Void
    
    @State private var questionText = ""
    @State private var plannerNote = ""
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Button("Cancel") {
                    onCancel()
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                Text("Custom Question")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    onSave(questionText, plannerNote)
                }
                .fontWeight(.semibold)
                .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.horizontal, 20)
            }
            .padding(.top, 16)
            
            TextField("Enter your question here...", text: $questionText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(width: UIScreen.main.bounds.width - 40)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

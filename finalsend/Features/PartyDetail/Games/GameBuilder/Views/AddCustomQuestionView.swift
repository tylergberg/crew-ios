import SwiftUI

struct AddCustomQuestionView: View {
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var questionText = ""
    @State private var plannerNote = ""
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Text("Custom Question")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Save") {
                    onSave(questionText, plannerNote)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(questionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            TextField("Enter your question here...", text: $questionText, axis: .vertical)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .lineLimit(3...6)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

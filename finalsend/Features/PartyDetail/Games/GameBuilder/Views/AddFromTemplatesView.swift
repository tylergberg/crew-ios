import SwiftUI

struct AddFromTemplatesView: View {
    let onSave: (String, String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedQuestions: Set<String> = []
    
    private let templateQuestions = [
        "When did you first realize you were in love?",
        "What's your partner's biggest pet peeve?",
        "Where was your first date?",
        "What's your partner's favorite food?",
        "What's the most embarrassing thing that happened to your partner?",
        "What's your partner's dream vacation destination?",
        "What's your partner's biggest fear?",
        "What's your partner's proudest moment?",
        "What's your partner's favorite movie?",
        "What's your partner's most annoying habit?"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(templateQuestions, id: \.self) { question in
                            HStack(spacing: 16) {
                                Button(action: {
                                    if selectedQuestions.contains(question) {
                                        selectedQuestions.remove(question)
                                    } else {
                                        selectedQuestions.insert(question)
                                    }
                                }) {
                                    Image(systemName: selectedQuestions.contains(question) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(selectedQuestions.contains(question) ? .blue : .secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(question)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                
                                Spacer()
                            }
                            .padding(12)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Template Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add (\(selectedQuestions.count))") {
                        for question in selectedQuestions {
                            onSave(question, "")
                        }
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(selectedQuestions.isEmpty)
                }
            }
        }
    }
}

import SwiftUI

struct AddFromTemplatesView: View {
    let onSave: (String, String) -> Void
    let game: PartyGame?
    @Environment(\.dismiss) private var dismiss
    @State private var selectedQuestions: Set<String> = []
    
    private var personalizedTemplateQuestions: [String] {
        guard let game = game else { return templateQuestions }
        
        return templateQuestions.map { question in
            game.personalizeQuestion(question)
        }
    }
    
    private let templateQuestions = [
        "When did you first realize you were in love?",
        "What's [Y]'s biggest pet peeve?",
        "Where was your first date?",
        "What's [Y]'s favorite food?",
        "What's the most embarrassing thing that happened to [Y]?",
        "What's [Y]'s dream vacation destination?",
        "What's [Y]'s biggest fear?",
        "What's [Y]'s proudest moment?",
        "What's [Y]'s favorite movie?",
        "What's [Y]'s most annoying habit?",
        "What's one chore that [Y] absolutely hates?",
        "What's [Y]'s go-to comfort food?",
        "What's [Y]'s biggest pet peeve?"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(Array(personalizedTemplateQuestions.enumerated()), id: \.offset) { index, question in
                            HStack(spacing: 16) {
                                Button(action: {
                                    let questionIndex = String(index)
                                    if selectedQuestions.contains(questionIndex) {
                                        selectedQuestions.remove(questionIndex)
                                    } else {
                                        selectedQuestions.insert(questionIndex)
                                    }
                                }) {
                                    Image(systemName: selectedQuestions.contains(String(index)) ? "checkmark.circle.fill" : "circle")
                                        .font(.title2)
                                        .foregroundColor(selectedQuestions.contains(String(index)) ? .blue : .secondary)
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                Text(question)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .lineLimit(3)
                                
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
                        for questionIndex in selectedQuestions {
                            if let index = Int(questionIndex) {
                                onSave(templateQuestions[index], "")
                            }
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

import SwiftUI

struct GameBuilderView: View {
    let partyId: String
    let gameId: String?
    let gameTitle: String
    let onGameSaved: (() -> Void)?
    
    @StateObject private var builderStore = GameBuilderStore()
    @Environment(\.dismiss) private var dismiss
    @State private var showingAddCustomQuestion = false
    @State private var showingAddFromTemplates = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                headerView
                Divider()
                questionsContentView
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Game Builder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await builderStore.saveGame()
                            // Call the callback to notify parent that game was saved
                            onGameSaved?()
                            dismiss()
                        }
                    }
                    .fontWeight(.semibold)
                    .disabled(builderStore.questions.isEmpty || builderStore.isLoading)
                }
            }
        }
        .onAppear {
            if let gameId = gameId {
                builderStore.loadExistingGame(gameId: gameId)
            }
            // Set the callback for when the game is saved
            builderStore.onGameSaved = onGameSaved
        }
        .overlay(
            Group {
                if showingAddCustomQuestion {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            showingAddCustomQuestion = false
                        }
                    
                    AddCustomQuestionView(
                        onSave: { questionText, plannerNote in
                            builderStore.addCustomQuestion(text: questionText, plannerNote: plannerNote)
                            showingAddCustomQuestion = false
                        },
                        onCancel: {
                            showingAddCustomQuestion = false
                        }
                    )
                }
            }
        )
        .sheet(isPresented: $showingAddFromTemplates) {
            AddFromTemplatesView(
                onSave: { questionText, plannerNote in
                    builderStore.addTemplateQuestion(text: questionText, plannerNote: plannerNote)
                },
                game: createTemporaryGame()
            )
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            Button("Add Custom Question") {
                showingAddCustomQuestion = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.blue)
            .cornerRadius(10)
            
            Button("Add from Templates") {
                showingAddFromTemplates = true
            }
            .font(.subheadline)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.green)
            .cornerRadius(10)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(Color(.systemBackground))
        .padding(.bottom, 20)
    }
    
    // MARK: - Questions Content View
    @ViewBuilder
    private var questionsContentView: some View {
        if builderStore.isLoading {
            loadingView
        } else if let error = builderStore.error {
            errorView(error: error)
        } else if builderStore.questions.isEmpty {
            emptyQuestionsView
        } else {
            questionsListView
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            Text("Loading questions...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Error View
    private func errorView(error: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.red)
            Text("Error loading game")
                .font(.headline)
                .foregroundColor(.primary)
            Text(error)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Empty Questions View
    private var emptyQuestionsView: some View {
        VStack(spacing: 24) {
            Image(systemName: "questionmark.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Questions Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Add your first question to get started building your game.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Questions List View
    private var questionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(builderStore.questions.enumerated()), id: \.element.id) { index, question in
                    buildQuestionCard(for: question, at: index)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Space for save button
        }
    }
    
    // MARK: - Build Question Card
    private func buildQuestionCard(for question: GameQuestion, at index: Int) -> some View {
        QuestionCard(
            question: question,
            index: index,
            onUpdate: { updatedQuestion in
                builderStore.updateQuestion(updatedQuestion)
            },
            onDelete: {
                builderStore.removeQuestion(id: question.id)
            },
            onMoveUp: index > 0 ? {
                print("🔄 Move Up tapped for question \(index + 1)")
                print("📝 Current questions count: \(builderStore.questions.count)")
                print("📝 Can move up: \(index > 0)")
                let sourceIndexSet = IndexSet(integer: index)
                print("📝 Moving from index \(index) to index \(index - 1)")
                builderStore.moveQuestion(from: sourceIndexSet, to: index - 1)
            } : nil,
            onMoveDown: index < builderStore.questions.count - 1 ? {
                print("🔄 Move Down tapped for question \(index + 1)")
                print("📝 Current questions count: \(builderStore.questions.count)")
                print("📝 Can move down: \(index < builderStore.questions.count - 1)")
                let sourceIndexSet = IndexSet(integer: index)
                print("📝 Moving from index \(index) to index \(index + 1)")
                builderStore.moveQuestion(from: sourceIndexSet, to: index + 1)
            } : nil
        )
    }
    
    // MARK: - Helper Methods
    private func createTemporaryGame() -> PartyGame? {
        // Create a temporary PartyGame object for template personalization
        // This is only used for displaying personalized template questions
        return PartyGame(
            partyId: UUID(uuidString: partyId) ?? UUID(),
            createdBy: UUID(), // This won't be used for personalization
            gameType: .newlywed, // Default type
            title: gameTitle,
            recorderName: builderStore.recorderName.isEmpty ? nil : builderStore.recorderName,
            livePlayerName: builderStore.livePlayerName.isEmpty ? nil : builderStore.livePlayerName,
            questions: builderStore.questions,
            answers: [:],
            videos: [:],
            status: .notStarted
        )
    }
}

// MARK: - Question Card
struct QuestionCard: View {
    let question: GameQuestion
    let index: Int
    let onUpdate: (GameQuestion) -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?
    
    @State private var isEditing = false
    @State private var editedText = ""
    @State private var editedPlannerNote = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            questionHeader
            questionContent
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Question Header
    private var questionHeader: some View {
        HStack {
            Text("Question \(index + 1)")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(.systemGray6))
                .cornerRadius(6)
            
            Spacer()
            
            HStack(spacing: 8) {
                Menu {
                    Button(action: {
                        editedText = question.text
                        editedPlannerNote = question.plannerNote ?? ""
                        isEditing = true
                    }) {
                        Label("Edit Question", systemImage: "pencil")
                    }
                    
                    if let onMoveUp = onMoveUp {
                        Button(action: onMoveUp) {
                            Label("Move Up", systemImage: "chevron.up")
                        }
                    }
                    
                    if let onMoveDown = onMoveDown {
                        Button(action: onMoveDown) {
                            Label("Move Down", systemImage: "chevron.down")
                        }
                    }
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Question", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    

    
    // MARK: - Question Content
    @ViewBuilder
    private var questionContent: some View {
        if isEditing {
            editingView
        } else {
            displayView
        }
    }
    
    // MARK: - Editing View
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Question text", text: $editedText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            TextField("Planner note (optional)", text: $editedPlannerNote)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.caption)
            
            editingButtons
        }
    }
    
    // MARK: - Editing Buttons
    private var editingButtons: some View {
        HStack {
            Button("Save") {
                let updatedQuestion = GameQuestion(
                    id: question.id,
                    text: editedText,
                    category: question.category,
                    isCustom: question.isCustom,
                    plannerNote: editedPlannerNote.isEmpty ? nil : editedPlannerNote,
                    questionForRecorder: editedText,
                    questionForLiveGuest: editedText
                )
                onUpdate(updatedQuestion)
                isEditing = false
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.blue)
            .cornerRadius(6)
            
            Button("Cancel") {
                editedText = question.text
                editedPlannerNote = question.plannerNote ?? ""
                isEditing = false
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Display View
    private var displayView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.text)
                .font(.body)
                .foregroundColor(.primary)
        }
    }
}

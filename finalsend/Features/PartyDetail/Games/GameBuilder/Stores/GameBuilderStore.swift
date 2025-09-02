import Foundation
import SwiftUI

@MainActor
class GameBuilderStore: ObservableObject {
    @Published var questions: [GameQuestion] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let gamesService = PartyGamesService.shared
    
    init() {
        print("🔄 GameBuilderStore initialized")
        print("📝 Initial questions count: \(questions.count)")
    }
    
    func addCustomQuestion(text: String, plannerNote: String) {
        print("🔄 addCustomQuestion called with text: \(text)")
        let newQuestion = GameQuestion(
            id: UUID().uuidString,
            text: text,
            category: "relationship_romance",
            isCustom: true,
            plannerNote: plannerNote.isEmpty ? nil : plannerNote,
            questionForRecorder: text,
            questionForLiveGuest: "What does your partner say about: \(text)"
        )
        
        questions.append(newQuestion)
        print("✅ Added custom question. New count: \(questions.count)")
    }
    
    func addTemplateQuestion(text: String, plannerNote: String) {
        print("🔄 addTemplateQuestion called with text: \(text)")
        let templateQuestion = GameQuestion(
            id: UUID().uuidString,
            text: text,
            category: "relationship_romance",
            isCustom: false,
            plannerNote: plannerNote.isEmpty ? nil : plannerNote,
            questionForRecorder: text,
            questionForLiveGuest: "What does your partner say about: \(text)"
        )
        
        questions.append(templateQuestion)
        print("✅ Added template question. New count: \(questions.count)")
    }
    
    func removeQuestion(id: String) {
        print("🔄 removeQuestion called with id: \(id)")
        questions.removeAll { $0.id == id }
        print("✅ Removed question. New count: \(questions.count)")
    }
    
    func moveQuestion(from source: IndexSet, to destination: Int) {
        print("🔄 moveQuestion called")
        questions.move(fromOffsets: source, toOffset: destination)
        print("✅ Moved question. New count: \(questions.count)")
    }
    
    func updateQuestion(_ question: GameQuestion) {
        print("🔄 updateQuestion called for question: \(question.id)")
        if let index = questions.firstIndex(where: { $0.id == question.id }) {
            questions[index] = question
            print("✅ Updated question at index \(index)")
        } else {
            print("❌ Question not found for update")
        }
    }
    
    func loadExistingGame(gameId: String) {
        print("🔄 loadExistingGame called with gameId: \(gameId)")
        print("📝 Current questions count before loading: \(questions.count)")
        
        isLoading = true
        error = nil
        
        Task {
            do {
                print("🔄 Fetching game from service...")
                if let game = try await gamesService.fetchGame(id: gameId) {
                    print("✅ Game loaded successfully: \(game.title)")
                    print("📝 Questions count: \(game.questions.count)")
                    print("📝 Questions: \(game.questions)")
                    
                    await MainActor.run {
                        self.questions = game.questions
                        self.isLoading = false
                        print("🔄 Updated questions array: \(self.questions.count) questions")
                        print("✅ Loading completed successfully")
                    }
                } else {
                    print("❌ Game not found")
                    await MainActor.run {
                        self.error = "Game not found"
                        self.isLoading = false
                        print("❌ Loading failed - game not found")
                    }
                }
            } catch {
                print("❌ Error loading game: \(error)")
                await MainActor.run {
                    self.error = "Failed to load game: \(error.localizedDescription)"
                    self.isLoading = false
                    print("❌ Loading failed with error: \(error)")
                }
            }
        }
    }
    
    func saveGame() {
        print("🔄 saveGame called")
        print("📝 Questions to save: \(questions.count)")
        
        guard !questions.isEmpty else {
            print("❌ No questions to save")
            error = "No questions to save"
            return
        }
        
        isLoading = true
        error = nil
        
        // For now, just simulate saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            self.isLoading = false
            print("✅ Game saved successfully (simulated)")
        }
    }
}

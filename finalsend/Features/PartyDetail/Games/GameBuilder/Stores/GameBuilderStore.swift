import Foundation
import SwiftUI

@MainActor
class GameBuilderStore: ObservableObject {
    @Published var questions: [GameQuestion] = []
    @Published var videos: [String: GameVideo] = [:]
    @Published var recorderName: String = ""
    @Published var livePlayerName: String = ""
    @Published var isLoading = false
    @Published var error: String?
    @Published var currentGame: PartyGame?
    
    private let gamesService = PartyGamesService.shared
    private var gameId: String?
    var onGameSaved: (() -> Void)?
    
    init() {
        print("🔄 GameBuilderStore initialized")
        print("📝 Initial questions count: \(questions.count)")
    }
    
    // MARK: - Helper Functions
    
    private func replacePlaceholders(in text: String) -> String {
        return PlaceholderReplacer.replacePlaceholders(
            in: text,
            recorderName: recorderName,
            livePlayerName: livePlayerName
        )
    }
    
    func addCustomQuestion(text: String, plannerNote: String) {
        print("🔄 addCustomQuestion called with text: \(text)")
        
        // Replace placeholders with actual names
        let processedText = replacePlaceholders(in: text)
        let processedRecorderText = replacePlaceholders(in: text)
        let processedLiveGuestText = replacePlaceholders(in: "What does your partner say about: \(text)")
        
        let newQuestion = GameQuestion(
            id: UUID().uuidString,
            text: processedText,
            category: "relationship_romance",
            isCustom: true,
            plannerNote: plannerNote.isEmpty ? nil : plannerNote,
            questionForRecorder: processedRecorderText,
            questionForLiveGuest: processedLiveGuestText
        )
        
        questions.append(newQuestion)
        print("✅ Added custom question with replaced placeholders. New count: \(questions.count)")
    }
    
    func addTemplateQuestion(text: String, plannerNote: String) {
        print("🔄 addTemplateQuestion called with text: \(text)")
        
        // Replace placeholders with actual names
        let processedText = replacePlaceholders(in: text)
        let processedRecorderText = replacePlaceholders(in: text)
        let processedLiveGuestText = replacePlaceholders(in: "What does your partner say about: \(text)")
        
        let templateQuestion = GameQuestion(
            id: UUID().uuidString,
            text: processedText,
            category: "relationship_romance",
            isCustom: false,
            plannerNote: plannerNote.isEmpty ? nil : plannerNote,
            questionForRecorder: processedRecorderText,
            questionForLiveGuest: processedLiveGuestText
        )
        
        questions.append(templateQuestion)
        print("✅ Added template question with replaced placeholders. New count: \(questions.count)")
    }
    
    func removeQuestion(id: String) {
        print("🔄 removeQuestion called with id: \(id)")
        questions.removeAll { $0.id == id }
        print("✅ Removed question. New count: \(questions.count)")
    }
    
    func moveQuestion(from source: IndexSet, to destination: Int) {
        print("🔄 moveQuestion called")
        print("📝 Source indices: \(source)")
        print("📝 Destination: \(destination)")
        print("📝 Questions before move: \(questions.map { $0.text })")
        
        guard let sourceIndex = source.first else {
            print("❌ No source index found")
            return
        }
        
        let questionToMove = questions[sourceIndex]
        questions.remove(at: sourceIndex)
        
        let adjustedDestination = destination > sourceIndex ? destination - 1 : destination
        questions.insert(questionToMove, at: adjustedDestination)
        
        print("📝 Questions after move: \(questions.map { $0.text })")
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
        self.gameId = gameId
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
                        self.currentGame = game // Store the full game object
                        self.recorderName = game.recorderName ?? ""
                        self.livePlayerName = game.livePlayerName ?? ""
                        
                        // Process existing questions to replace placeholders
                        self.questions = game.questions.map { question in
                            GameQuestion(
                                id: question.id,
                                text: self.replacePlaceholders(in: question.text),
                                category: question.category,
                                isCustom: question.isCustom,
                                plannerNote: question.plannerNote,
                                questionForRecorder: self.replacePlaceholders(in: question.questionForRecorder),
                                questionForLiveGuest: self.replacePlaceholders(in: question.questionForLiveGuest)
                            )
                        }
                        
                        self.videos = game.videos
                        self.isLoading = false
                        print("🔄 Updated questions array: \(self.questions.count) questions")
                        print("🎥 Loaded videos: \(self.videos.count) videos")
                        print("📝 Recorder: \(self.recorderName), Live Player: \(self.livePlayerName)")
                        print("✅ Loading completed successfully with placeholder replacement")
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
    
    func saveGame() async {
        print("🔄 saveGame called")
        print("📝 Questions to save: \(questions.count)")
        
        guard let gameId = gameId else {
            print("❌ No game ID available for saving")
            error = "No game ID available for saving"
            return
        }
        
        guard !questions.isEmpty else {
            print("❌ No questions to save")
            error = "No questions to save"
            return
        }
        
        isLoading = true
        error = nil
        
        do {
            print("🔄 Saving questions to database...")
            print("📝 Game ID: \(gameId)")
            print("📝 Questions count: \(questions.count)")
            print("📝 Questions: \(questions.map { $0.text })")
            
            let success = try await gamesService.updateGameQuestions(
                gameId: gameId, 
                questions: questions, 
                recorderName: recorderName.isEmpty ? nil : recorderName,
                livePlayerName: livePlayerName.isEmpty ? nil : livePlayerName
            )
            
            if success {
                print("✅ Game saved successfully to database")
                error = nil
                
                // Notify parent to refresh games
                await MainActor.run {
                    onGameSaved?()
                }
            } else {
                print("❌ Failed to save game")
                error = "Failed to save game"
            }
        } catch {
            print("❌ Error saving game: \(error)")
            print("❌ Error details: \(error)")
            self.error = "Failed to save game: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
}

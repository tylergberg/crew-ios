import Foundation
import Supabase

@MainActor
class PartyGamesService: ObservableObject {
    static let shared = PartyGamesService()
    
    private let supabase: SupabaseClient
    
    private init() {
        self.supabase = SupabaseManager.shared.client
    }
    
    // MARK: - Game Management
    
    /// Fetch all games for a party
    func fetchGames(partyId: String) async throws -> [PartyGame] {
        do {
            let response: [PartyGame] = try await supabase
                .from("party_games")
                .select()
                .eq("party_id", value: partyId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            return response
        } catch {
            print("❌ Error fetching games: \(error)")
            // Return empty array if there's an error
            return []
        }
    }
    
    /// Fetch a specific game by ID
    func fetchGame(id: String) async throws -> PartyGame? {
        do {
            let response: PartyGame = try await supabase
                .from("party_games")
                .select()
                .eq("id", value: id)
                .single()
                .execute()
                .value
            
            print("✅ fetchGame: Retrieved game with title: \(response.title)")
            return response
        } catch {
            print("❌ fetchGame error: \(error)")
            throw error
        }
    }
    
    /// Create a new game
    func createGame(
        partyId: String,
        title: String,
        gameType: GameType = .newlywed
    ) async throws -> PartyGame {
        struct CreateGameRequest: Codable {
            let party_id: String
            let title: String
            let game_type: String
            let questions: [GameQuestion]
            let status: String
        }
        
        let newGame = CreateGameRequest(
            party_id: partyId,
            title: title,
            game_type: gameType.rawValue,
            questions: GameQuestion.defaultNewlywedQuestions,
            status: GameStatus.notStarted.rawValue
        )
        
        do {
            let response: PartyGame = try await supabase
                .from("party_games")
                .insert(newGame)
                .select()
                .single()
                .execute()
                .value
            
            print("✅ Game created successfully: \(response.title)")
            return response
        } catch {
            print("❌ Error creating game: \(error)")
            throw error
        }
    }
    
    /// Update game questions
    func updateGameQuestions(gameId: String, questions: [GameQuestion]) async throws -> Bool {
        struct UpdateQuestionsRequest: Codable {
            let questions: [GameQuestion]
        }
        
        let updateData = UpdateQuestionsRequest(questions: questions)
        
        try await supabase
            .from("party_games")
            .update(updateData)
            .eq("id", value: gameId)
            .execute()
        
        return true
    }
    
    /// Lock questions for a game
    func lockQuestions(gameId: String) async throws -> Bool {
        struct LockQuestionsRequest: Codable {
            let question_lock_status: String
            let status: String
            let locked_at: String
        }
        
        let updateData = LockQuestionsRequest(
            question_lock_status: QuestionLockStatus.locked.rawValue,
            status: GameStatus.ready.rawValue,
            locked_at: ISO8601DateFormatter().string(from: Date())
        )
        
        try await supabase
            .from("party_games")
            .update(updateData)
            .eq("id", value: gameId)
            .execute()
        
        return true
    }
    
    /// Unlock questions for a game
    func unlockQuestions(gameId: String) async throws -> Bool {
        struct UnlockQuestionsRequest: Codable {
            let question_lock_status: String
            let status: String
            let locked_at: String?
        }
        
        let updateData = UnlockQuestionsRequest(
            question_lock_status: QuestionLockStatus.unlocked.rawValue,
            status: GameStatus.notStarted.rawValue,
            locked_at: nil
        )
        
        try await supabase
            .from("party_games")
            .update(updateData)
            .eq("id", value: gameId)
            .execute()
        
        return true
    }
    
    /// Delete a game
    func deleteGame(gameId: String) async throws -> Bool {
        try await supabase
            .from("party_games")
            .delete()
            .eq("id", value: gameId)
            .execute()
        
        return true
    }
    
    // MARK: - Video Management
    
    /// Upload video for a question
    func uploadVideo(
        gameId: String,
        questionId: String,
        videoURL: URL,
        respondentName: String
    ) async throws -> GameVideo {
        // First, upload the video file to storage
        let fileName = "\(gameId)/\(questionId)/\(UUID().uuidString).mp4"
        
        let fileData = try Data(contentsOf: videoURL)
        let _ = try await supabase.storage
            .from("game-videos")
            .upload(
                path: fileName,
                file: fileData,
                options: FileOptions(contentType: "video/mp4")
            )
        
        // Get the public URL
        let publicURL = try supabase.storage
            .from("game-videos")
            .getPublicURL(path: fileName)
        
        // Update the game's videos field
        let currentGame = try await fetchGame(id: gameId)
        var updatedVideos = currentGame?.videos ?? [:]
        updatedVideos[questionId] = GameVideo(
            questionId: questionId,
            videoUrl: publicURL.absoluteString,
            thumbnailUrl: nil,
            uploadedAt: Date(),
            duration: nil,
            respondentName: respondentName
        )
        
        struct UpdateVideosRequest: Codable {
            let videos: [String: GameVideo]
        }
        
        let updateData = UpdateVideosRequest(videos: updatedVideos)
        
        try await supabase
            .from("party_games")
            .update(updateData)
            .eq("id", value: gameId)
            .execute()
        
        return updatedVideos[questionId]!
    }
    
    /// Get video URL for a question
    func getVideoURL(gameId: String, questionId: String) async throws -> String? {
        let game = try await fetchGame(id: gameId)
        return game?.videos[questionId]?.videoUrl
    }
    
    // MARK: - Game Play
    
    /// Start a game session
    func startGameSession(gameId: String) async throws -> Bool {
        struct StartGameRequest: Codable {
            let status: String
        }
        
        let updateData = StartGameRequest(status: GameStatus.inProgress.rawValue)
        
        try await supabase
            .from("party_games")
            .update(updateData)
            .eq("id", value: gameId)
            .execute()
        
        return true
    }
    
    /// Complete a game session
    func completeGameSession(gameId: String, answers: [String: GameAnswer]) async throws -> Bool {
        struct CompleteGameRequest: Codable {
            let status: String
            let answers: [String: GameAnswer]
        }
        
        let updateData = CompleteGameRequest(
            status: GameStatus.complete.rawValue,
            answers: answers
        )
        
        try await supabase
            .from("party_games")
            .update(updateData)
            .eq("id", value: gameId)
            .execute()
        
        return true
    }
    
    // MARK: - Utility Methods
    
    /// Check if a game is ready to play
    func isGameReadyToPlay(_ game: PartyGame) -> Bool {
        return game.status == .ready && 
               game.questionCount > 0 && 
               game.answerCount == game.questionCount
    }
    
    /// Get game progress
    func getGameProgress(_ game: PartyGame) -> (completed: Int, total: Int, percentage: Double) {
        let completed = game.answerCount
        let total = game.questionCount
        let percentage = total > 0 ? Double(completed) / Double(total) : 0
        
        return (completed, total, percentage)
    }
}

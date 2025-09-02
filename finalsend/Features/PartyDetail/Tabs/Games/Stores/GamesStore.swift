import Foundation
import SwiftUI

@MainActor
class GamesStore: ObservableObject {
    @Published var games: [PartyGame] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var selectedTab: GameTab = .browse
    
    private let gamesService = PartyGamesService.shared
    private let partyId: String
    
    init(partyId: String) {
        self.partyId = partyId
        print("🔄 [GamesStore] Initialized for party: \(partyId)")
    }
    
    // MARK: - Public Methods
    
    /// Load all games for the party
    func loadGames() async {
        print("🔄 [GamesStore] loadGames() called for party: \(partyId)")
        print("🔄 [GamesStore] Setting isLoading to true")
        isLoading = true
        error = nil
        
        do {
            print("🔄 [GamesStore] Fetching games from service...")
            games = try await gamesService.fetchGames(partyId: partyId)
            print("✅ [GamesStore] Successfully loaded \(games.count) games")
        } catch {
            self.error = error
            print("❌ [GamesStore] Error loading games: \(error)")
        }
        
        print("🔄 [GamesStore] Setting isLoading to false")
        isLoading = false
        print("🔄 [GamesStore] Final state - games.count: \(games.count), isLoading: \(isLoading)")
    }
    
    /// Create a new game
    func createGame(title: String, gameType: GameType = .newlywed) async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let newGame = try await gamesService.createGame(
                partyId: partyId,
                title: title,
                gameType: gameType
            )
            
            games.insert(newGame, at: 0)
            selectedTab = .myGames
            
            isLoading = false
            return true
        } catch {
            self.error = error
            print("❌ Error creating game: \(error)")
            isLoading = false
            return false
        }
    }
    
    /// Delete a game
    func deleteGame(_ game: PartyGame) async -> Bool {
        do {
            let success = try await gamesService.deleteGame(gameId: game.id.uuidString)
            if success {
                games.removeAll { $0.id == game.id }
            }
            return success
        } catch {
            self.error = error
            print("❌ Error deleting game: \(error)")
            return false
        }
    }
    
    /// Update a game
    func updateGame(_ game: PartyGame) {
        if let index = games.firstIndex(where: { $0.id == game.id }) {
            games[index] = game
        }
    }
    
    /// Refresh games data
    func refresh() async {
        await loadGames()
    }
    
    // MARK: - Computed Properties
    
    var browseGames: [PartyGame] {
        // For now, return default games that can be created
        return []
    }
    
    var myGames: [PartyGame] {
        return games
    }
    
    var hasGames: Bool {
        return !games.isEmpty
    }
    
    var canCreateGame: Bool {
        // Check if user has permission to create games
        // This will be enhanced with user role checking
        return true
    }
    
    var currentPartyId: String {
        return partyId
    }
}

import SwiftUI

struct GamesTabView: View {
    let userRole: String
    let partyId: String
    
    @StateObject private var gamesStore: GamesStore
    @State private var showingCreateGame = false
    @State private var showingDeleteAlert = false
    @State private var gameToDelete: PartyGame?
    @Environment(\.dismiss) private var dismiss
    
    init(userRole: String, partyId: String) {
        self.userRole = userRole
        self.partyId = partyId
        self._gamesStore = StateObject(wrappedValue: GamesStore(partyId: partyId))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Game Tab", selection: $gamesStore.selectedTab) {
                    Text("Browse Games").tag(GameTab.browse)
                    Text("My Games").tag(GameTab.myGames)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Tab Content
                TabView(selection: $gamesStore.selectedTab) {
                    BrowseGamesView(
                        gamesStore: gamesStore,
                        showingCreateGame: $showingCreateGame
                    )
                    .tag(GameTab.browse)
                    
                                                MyGamesView(
                        gamesStore: gamesStore,
                        showingDeleteAlert: $showingDeleteAlert,
                        gameToDelete: $gameToDelete
                    )
                    .tag(GameTab.myGames)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Back") {
                        dismiss()
                    }
                    .font(.headline)
                    .foregroundColor(.blue)
                }
            }
            .sheet(isPresented: $showingCreateGame) {
                CreateGameView(gamesStore: gamesStore)
            }
            .alert("Delete Game", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    if let game = gameToDelete {
                        Task {
                            await gamesStore.deleteGame(game)
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Are you sure you want to delete this game? This action cannot be undone.")
            }
        }
        .task {
            await gamesStore.loadGames()
        }
    }
}

// MARK: - Browse Games View
struct BrowseGamesView: View {
    @ObservedObject var gamesStore: GamesStore
    @Binding var showingCreateGame: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                NearlywedGameCard(showingCreateGame: $showingCreateGame)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
        }
        .refreshable {
            await gamesStore.loadGames()
        }
    }
}

// MARK: - Nearlywed Game Card
struct NearlywedGameCard: View {
    @Binding var showingCreateGame: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                Image("nearlywed-game")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            colors: [.black.opacity(0.3), .clear],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Nearlywed Game")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Test how well you know your partner with fun questions about your relationship.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
            }
            
            VStack(spacing: 12) {
                Button("Create Game") {
                    showingCreateGame = true
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
                
                Button("Learn More") {
                    // TODO: Show game details
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - My Games View
struct MyGamesView: View {
    @ObservedObject var gamesStore: GamesStore
    @Binding var showingDeleteAlert: Bool
    @Binding var gameToDelete: PartyGame?
    @State private var gameToEdit: PartyGame?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if gamesStore.games.isEmpty {
                    EmptyGamesView()
                        .padding(.horizontal, 20)
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(gamesStore.games, id: \.id) { game in
                            MyGameCard(
                                game: game,
                                onDelete: {
                                    gameToDelete = game
                                    showingDeleteAlert = true
                                },
                                onEnterBuilder: {
                                    print("🎯 [MyGamesView] Enter Game Builder tapped for game: \(game.title)")
                                    
                                    // Set the game to trigger the sheet
                                    gameToEdit = game
                                    
                                    print("🎯 [MyGamesView] gameToEdit: \(gameToEdit?.title ?? "nil")")
                                }
                            )
                            .padding(.horizontal, 20)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.top, 20)
        }
        .refreshable {
            await gamesStore.loadGames()
        }
        .fullScreenCover(item: $gameToEdit) { game in
            GameBuilderView(
                partyId: gamesStore.currentPartyId,
                gameId: game.id.uuidString,
                gameTitle: game.title
            )
        }
        .overlay(
            ZStack {
                if gamesStore.isLoading {
                    VStack {
                        ProgressView()
                            .scaleEffect(1.2)
                        Text("Loading games...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground).opacity(0.8))
                }
            }
        )
    }
}

// MARK: - My Game Card
struct MyGameCard: View {
    let game: PartyGame
    let onDelete: () -> Void
    let onEnterBuilder: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Game Photo
            Image("nearlywed-game")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(height: 120)
                .clipped()
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.3), .clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(12)
                .overlay(
                    HStack {
                        Spacer()
                        Menu {
                            Button(action: onEnterBuilder) {
                                Label("Edit Game", systemImage: "pencil")
                            }
                            
                            Button(role: .destructive, action: onDelete) {
                                Label("Delete Game", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding(12),
                    alignment: .topTrailing
                )
            
            // Game Title
            Text(game.title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
            
            HStack(spacing: 20) {
                VStack(spacing: 4) {
                    Text("\(game.questions.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(game.answers.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Answers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(spacing: 4) {
                    Text("\(game.videos.count)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    Text("Videos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            
            VStack(spacing: 12) {
                Button("Enter Game Builder") {
                    onEnterBuilder()
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
                
                Button("Play Game") {
                    // TODO: Hook up game play functionality
                }
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.green)
                .cornerRadius(10)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Empty Games View
struct EmptyGamesView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            
            Text("No Games Created Yet")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text("Create your first game to get started. You can build custom questions or use our templates.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Game Status Badge
struct GameStatusBadge: View {
    let status: GameStatus
    
    var body: some View {
        Text(status.displayName)
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor)
            .cornerRadius(6)
    }
    
    private var statusColor: Color {
        switch status {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .ready:
            return .orange
        case .complete:
            return .green
        }
    }
}

// MARK: - Game Tab Enum
enum GameTab: String, CaseIterable {
    case browse = "browse"
    case myGames = "myGames"
}


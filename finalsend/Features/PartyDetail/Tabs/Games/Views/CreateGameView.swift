import SwiftUI

struct CreateGameView: View {
    @ObservedObject var gamesStore: GamesStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var gameTitle = ""
    @State private var isCreating = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.orange)
                    
                    Text("Create New Game")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Give your game a memorable name")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)
                
                // Game Title Input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Game Name")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("e.g., Jared & Jaimee", text: $gameTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.body)
                        .autocapitalization(.words)
                        .disableAutocorrection(true)
                }
                .padding(.horizontal, 20)
                
                // Game Type Info
                VStack(spacing: 12) {
                    HStack {
                        Text("🎯")
                            .font(.title2)
                        Text("Nearlywed Game")
                            .font(.headline)
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    
                    Text("How well do the soon-to-be newlyweds really know each other? One partner secretly records video answers while the other answers live at the party.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Create Button
                Button(action: createGame) {
                    HStack(spacing: 8) {
                        if isCreating {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "plus")
                                .font(.headline)
                        }
                        Text(isCreating ? "Creating..." : "Create Game")
                            .font(.headline)
                            .fontWeight(.bold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(gameTitle.isEmpty ? Color.gray : Color.orange)
                    .cornerRadius(12)
                }
                .disabled(gameTitle.isEmpty || isCreating)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .navigationTitle("Create Game")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
        .alert("Error", isPresented: .constant(errorMessage != nil)) {
            Button("OK") {
                errorMessage = nil
            }
        } message: {
            if let errorMessage = errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func createGame() {
        guard !gameTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Please enter a game name"
            return
        }
        
        isCreating = true
        errorMessage = nil
        
        Task {
            let success = await gamesStore.createGame(
                title: gameTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            
            await MainActor.run {
                isCreating = false
                
                if success {
                    dismiss()
                } else {
                    errorMessage = "Failed to create game. Please try again."
                }
            }
        }
    }
}

#Preview {
    CreateGameView(gamesStore: GamesStore(partyId: "test-party-id"))
}

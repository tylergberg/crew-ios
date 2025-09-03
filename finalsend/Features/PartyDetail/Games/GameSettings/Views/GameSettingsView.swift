import SwiftUI
import Combine

struct GameSettingsView: View {
    let game: PartyGame
    let partyId: String
    let onGameUpdated: (PartyGame) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = GameSettingsViewModel()
    @State private var showingDeleteConfirmation = false
    @State private var deleteConfirmationText = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Game Title Section
                    GameTitleEditCard(
                        game: game,
                        onTitleUpdated: onGameUpdated
                    )
                    
                    // Player Names Section
                    PlayerNamesCard(
                        game: game,
                        onNamesUpdated: onGameUpdated
                    )
                    
                    // External Recorder Assignment Section
                    ExternalRecorderAssignmentCard(
                        game: game,
                        partyId: partyId,
                        onAssignmentComplete: onGameUpdated
                    )
                    
                    // Danger Zone - Delete Game
                    DangerZoneCard(
                        game: game,
                        showingDeleteConfirmation: $showingDeleteConfirmation,
                        deleteConfirmationText: $deleteConfirmationText,
                        onGameDeleted: {
                            dismiss()
                        }
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Game Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - External Recorder Assignment Card
struct ExternalRecorderAssignmentCard: View {
    let game: PartyGame
    let partyId: String
    let onAssignmentComplete: (PartyGame) -> Void
    
    @StateObject private var phoneAuthService = PhoneAuthService.shared
    @State private var phoneNumber = ""
    @State private var isAssigning = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.badge.plus")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("External Recorder")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Assign someone outside the party to record video answers")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let recorderPhone = game.recorderPhone, !recorderPhone.isEmpty {
                // Show assigned recorder
                assignedRecorderView(phone: recorderPhone)
            } else {
                // Show assignment form
                assignmentFormView
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            phoneNumber = game.recorderPhone ?? ""
        }
    }
    
    // MARK: - Assigned Recorder View
    private func assignedRecorderView(phone: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Recorder Assigned")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                    
                    Text("Phone: \(formatPhoneNumber(phone))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            Text("This person will receive a recording task notification when they sign in to the app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.1))
                .cornerRadius(6)
            
            Button(action: removeAssignment) {
                Text("Remove Assignment")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
        }
    }
    
    // MARK: - Assignment Form View
    private var assignmentFormView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Phone Input
            VStack(alignment: .leading, spacing: 6) {
                Text("Recorder's Phone Number")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                HStack {
                    Image(systemName: "phone")
                        .foregroundColor(.secondary)
                    
                    TextField("(555) 123-4567", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                        .onChange(of: phoneNumber) { newValue in
                            phoneNumber = phoneAuthService.formatPhoneNumber(newValue)
                            errorMessage = ""
                        }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                if !phoneNumber.isEmpty && !phoneAuthService.validatePhoneNumber(phoneNumber) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.red)
                            .font(.caption)
                        
                        Text("Please enter a valid phone number")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
            }
            
            // Info Box
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundColor(.blue)
                    .font(.caption)
                
                Text("The person will get a task notification to record videos. If they don't have an account, they'll get the task when they sign up with this phone number.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(6)
            
            // Error/Success Messages
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(6)
            }
            
            if !successMessage.isEmpty {
                Text(successMessage)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(6)
            }
            
            // Assign Button
            Button(action: assignRecorder) {
                HStack {
                    if isAssigning {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "paperplane")
                    }
                    
                    Text(isAssigning ? "Assigning..." : "Assign External Recorder")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(phoneAuthService.validatePhoneNumber(phoneNumber) ? Color.blue : Color.gray)
                .cornerRadius(8)
            }
            .disabled(!phoneAuthService.validatePhoneNumber(phoneNumber) || isAssigning)
        }
    }
    
    // MARK: - Helper Methods
    private func formatPhoneNumber(_ phone: String) -> String {
        return phoneAuthService.formatPhoneNumber(phone)
    }
    
    private func assignRecorder() {
        guard phoneAuthService.validatePhoneNumber(phoneNumber) else {
            errorMessage = "Please enter a valid phone number"
            return
        }
        
        isAssigning = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                // Convert to E.164 format
                let digits = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
                let e164Phone = digits.count == 10 ? "+1\(digits)" : "+\(digits)"
                
                // Call the API to assign recorder
                let result = try await GameSettingsService.assignExternalRecorder(
                    gameId: game.id.uuidString,
                    partyId: partyId,
                    recorderPhone: e164Phone
                )
                
                await MainActor.run {
                    isAssigning = false
                    
                    if result.success {
                        // Create updated game with recorder info
                        let updatedGame = PartyGame(
                            id: game.id,
                            partyId: game.partyId,
                            createdBy: game.createdBy,
                            gameType: game.gameType,
                            title: game.title,
                            recorderName: game.recorderName,
                            recorderPhone: e164Phone,
                            livePlayerName: game.livePlayerName,
                            questions: game.questions,
                            answers: game.answers,
                            videos: game.videos,
                            status: game.status,
                            createdAt: game.createdAt,
                            updatedAt: game.updatedAt,
                            questionLockStatus: game.questionLockStatus,
                            questionVersion: game.questionVersion,
                            lockedAt: game.lockedAt,
                            recordingSettings: game.recordingSettings,
                            respondentProgress: game.respondentProgress
                        )
                        onAssignmentComplete(updatedGame)
                        
                        // Trigger task refresh to update notification badge
                        NotificationCenter.default.post(name: Notification.Name.refreshTaskCount, object: nil)
                        
                        successMessage = result.userExists 
                            ? "Task assigned to existing user. They will see a notification."
                            : "Pending task created. They will get the task when they sign up."
                    } else {
                        errorMessage = result.error ?? "Failed to assign recorder"
                    }
                }
            } catch {
                await MainActor.run {
                    isAssigning = false
                    errorMessage = "Failed to assign recorder: \(error.localizedDescription)"
                }
            }
        }
    }
    
    private func removeAssignment() {
        errorMessage = ""
        successMessage = ""
        isAssigning = true
        
        Task {
            do {
                // Call the API to remove recorder assignment
                let success = try await GameSettingsService.removeExternalRecorder(
                    gameId: game.id.uuidString,
                    partyId: partyId
                )
                
                await MainActor.run {
                    isAssigning = false
                    
                    if success {
                        // Create updated game without recorder info
                        let updatedGame = PartyGame(
                            id: game.id,
                            partyId: game.partyId,
                            createdBy: game.createdBy,
                            gameType: game.gameType,
                            title: game.title,
                            recorderName: game.recorderName,
                            recorderPhone: nil,
                            livePlayerName: game.livePlayerName,
                            questions: game.questions,
                            answers: game.answers,
                            videos: game.videos,
                            status: game.status,
                            createdAt: game.createdAt,
                            updatedAt: game.updatedAt,
                            questionLockStatus: game.questionLockStatus,
                            questionVersion: game.questionVersion,
                            lockedAt: game.lockedAt,
                            recordingSettings: game.recordingSettings,
                            respondentProgress: game.respondentProgress
                        )
                        onAssignmentComplete(updatedGame)
                        
                        // Trigger task refresh
                        NotificationCenter.default.post(name: Notification.Name.refreshTaskCount, object: nil)
                        
                        successMessage = "External recorder assignment removed successfully."
                    } else {
                        errorMessage = "Failed to remove assignment"
                    }
                }
            } catch {
                await MainActor.run {
                    isAssigning = false
                    errorMessage = "Failed to remove assignment: \(error.localizedDescription)"
                }
            }
        }
    }
}

// MARK: - Game Title Edit Card
struct GameTitleEditCard: View {
    let game: PartyGame
    let onTitleUpdated: (PartyGame) -> Void
    
    @State private var isEditing = false
    @State private var editedTitle = ""
    @State private var isUpdating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "pencil")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                Text("Game Title")
                    .font(.headline)
                    .fontWeight(.bold)
                
                Spacer()
            }
            
            if isEditing {
                editingView
            } else {
                displayView
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            editedTitle = game.title
        }
    }
    
    private var displayView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(game.title)
                .font(.body)
                .foregroundColor(.primary)
            
            Button("Edit Title") {
                editedTitle = game.title
                isEditing = true
            }
            .font(.caption)
            .fontWeight(.semibold)
            .foregroundColor(.blue)
        }
    }
    
    private var editingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField("Game title", text: $editedTitle)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Save") {
                    updateTitle()
                }
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.gray : Color.blue)
                .cornerRadius(6)
                .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isUpdating)
                
                Button("Cancel") {
                    editedTitle = game.title
                    isEditing = false
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
    
    private func updateTitle() {
        guard !editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        isUpdating = true
        
        // TODO: Implement title update API call
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let updatedGame = PartyGame(
                id: game.id,
                partyId: game.partyId,
                createdBy: game.createdBy,
                gameType: game.gameType,
                title: editedTitle.trimmingCharacters(in: .whitespacesAndNewlines),
                recorderName: game.recorderName,
                recorderPhone: game.recorderPhone,
                livePlayerName: game.livePlayerName,
                questions: game.questions,
                answers: game.answers,
                videos: game.videos,
                status: game.status,
                createdAt: game.createdAt,
                updatedAt: game.updatedAt,
                questionLockStatus: game.questionLockStatus,
                questionVersion: game.questionVersion,
                lockedAt: game.lockedAt,
                recordingSettings: game.recordingSettings,
                respondentProgress: game.respondentProgress
            )
            onTitleUpdated(updatedGame)
            isEditing = false
            isUpdating = false
        }
    }
}

// MARK: - Danger Zone Card
struct DangerZoneCard: View {
    let game: PartyGame
    @Binding var showingDeleteConfirmation: Bool
    @Binding var deleteConfirmationText: String
    let onGameDeleted: () -> Void
    
    @State private var isDeleting = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundColor(.red)
                
                Text("Danger Zone")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                
                Spacer()
            }
            
            if !showingDeleteConfirmation {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Permanently delete this game and all responses. This action cannot be undone.")
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Button("Delete Game") {
                        showingDeleteConfirmation = true
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.red, lineWidth: 1)
                    )
                }
            } else {
                confirmationView
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var confirmationView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type \"DELETE\" to confirm:")
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.red)
            
            TextField("DELETE", text: $deleteConfirmationText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            
            HStack {
                Button("Delete Game") {
                    deleteGame()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(deleteConfirmationText == "DELETE" ? Color.red : Color.gray)
                .cornerRadius(8)
                .disabled(deleteConfirmationText != "DELETE" || isDeleting)
                
                Button("Cancel") {
                    showingDeleteConfirmation = false
                    deleteConfirmationText = ""
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
            }
        }
    }
    
    private func deleteGame() {
        guard deleteConfirmationText == "DELETE" else { return }
        
        isDeleting = true
        
        // TODO: Implement delete game API call
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            onGameDeleted()
        }
    }
}

// MARK: - Game Settings View Model
class GameSettingsViewModel: ObservableObject {
    // Add any shared state or logic here
}

// MARK: - Player Names Card
struct PlayerNamesCard: View {
    let game: PartyGame
    let onNamesUpdated: (PartyGame) -> Void
    
    @State private var recorderName: String = ""
    @State private var livePlayerName: String = ""
    @State private var isUpdating = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.purple)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Player Names")
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text("Set the names for personalized questions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Recorder Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Recorder Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter recorder name", text: $recorderName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disabled(isUpdating)
            }
            
            // Live Player Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("Live Player Name")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                TextField("Enter live player name", text: $livePlayerName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.words)
                    .disabled(isUpdating)
            }
            
            // Update Button
            Button(action: updatePlayerNames) {
                HStack {
                    if isUpdating {
                        ProgressView()
                            .scaleEffect(0.8)
                            .foregroundColor(.white)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.subheadline)
                    }
                    
                    Text(isUpdating ? "Updating..." : "Update Names")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(hasChanges ? Color.purple : Color.gray)
                .cornerRadius(10)
            }
            .disabled(!hasChanges || isUpdating)
            
            // Status Messages
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }
            
            if !successMessage.isEmpty {
                Text(successMessage)
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.top, 4)
            }
        }
        .padding(20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        .onAppear {
            // Initialize with current values
            recorderName = game.recorderName ?? ""
            livePlayerName = game.livePlayerName ?? ""
        }
    }
    
    private var hasChanges: Bool {
        recorderName != (game.recorderName ?? "") || 
        livePlayerName != (game.livePlayerName ?? "")
    }
    
    private func updatePlayerNames() {
        guard hasChanges else { return }
        
        isUpdating = true
        errorMessage = ""
        successMessage = ""
        
        Task {
            do {
                // Create updated game with new names
                let updatedGame = PartyGame(
                    id: game.id,
                    partyId: game.partyId,
                    createdBy: game.createdBy,
                    gameType: game.gameType,
                    title: game.title,
                    recorderName: recorderName.isEmpty ? nil : recorderName,
                    recorderPhone: game.recorderPhone,
                    livePlayerName: livePlayerName.isEmpty ? nil : livePlayerName,
                    questions: game.questions,
                    answers: game.answers,
                    videos: game.videos,
                    status: game.status,
                    createdAt: game.createdAt,
                    updatedAt: Date(),
                    questionLockStatus: game.questionLockStatus,
                    questionVersion: game.questionVersion,
                    lockedAt: game.lockedAt,
                    recordingSettings: game.recordingSettings,
                    respondentProgress: game.respondentProgress
                )
                
                // Save via games service  
                _ = try await PartyGamesService.shared.updateGameQuestions(
                    gameId: game.id.uuidString,
                    questions: game.questions,
                    recorderName: recorderName.isEmpty ? nil : recorderName,
                    livePlayerName: livePlayerName.isEmpty ? nil : livePlayerName
                )
                
                await MainActor.run {
                    self.isUpdating = false
                    self.successMessage = "Player names updated successfully!"
                    
                    // Clear success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.successMessage = ""
                    }
                    
                    // Notify parent of update
                    onNamesUpdated(updatedGame)
                }
                
            } catch {
                await MainActor.run {
                    self.isUpdating = false
                    self.errorMessage = "Failed to update names: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    GameSettingsView(
        game: PartyGame(
            partyId: UUID(),
            createdBy: UUID(),
            gameType: .newlywed,
            title: "Our Nearlywed Game",
            questions: [],
            answers: [:],
            videos: [:],
            status: .notStarted
        ),
        partyId: UUID().uuidString,
        onGameUpdated: { _ in }
    )
}

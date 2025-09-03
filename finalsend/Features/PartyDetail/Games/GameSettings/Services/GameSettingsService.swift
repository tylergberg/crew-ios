import Foundation
import Supabase

// MARK: - Response Models
struct ExternalRecorderAssignmentResponse: Codable {
    let success: Bool
    let taskId: String?
    let userExists: Bool
    let message: String?
    let error: String?
}

// MARK: - Game Settings Service
@MainActor
class GameSettingsService: ObservableObject {
    private let client = SupabaseManager.shared.client
    
    // MARK: - External Recorder Assignment
    
    /// Assigns an external recorder to a game by phone number
    static func assignExternalRecorder(
        gameId: String,
        partyId: String,
        recorderPhone: String
    ) async throws -> ExternalRecorderAssignmentResponse {
        
        let client = SupabaseManager.shared.client
        
        guard let currentUserId = AuthManager.shared.currentUserId else {
            throw GameSettingsError.userNotAuthenticated
        }
        
        print("📞 GameSettingsService: Assigning external recorder")
        print("   Game ID: \(gameId)")
        print("   Party ID: \(partyId)")
        print("   Recorder Phone: \(recorderPhone)")
        print("   Created By: \(currentUserId)")
        
        do {
            // Call the database function to create recording task
            let response: String = try await client.rpc(
                "create_game_recording_task",
                params: [
                    "p_game_id": gameId,
                    "p_party_id": partyId,
                    "p_recorder_phone": recorderPhone,
                    "p_created_by": currentUserId
                ]
            ).execute().value
            
            print("✅ GameSettingsService: Database function response: \(response)")
            
            // Check if user already exists with this phone number
            let existingUserQuery = client
                .from("profiles")
                .select("id, full_name")
                .eq("phone", value: recorderPhone)
                .limit(1)
            
            let existingUsers: [UserProfile] = try await existingUserQuery.execute().value
            let userExists = !existingUsers.isEmpty
            
            let successResponse = ExternalRecorderAssignmentResponse(
                success: true,
                taskId: response,
                userExists: userExists,
                message: userExists 
                    ? "Task assigned to existing user. They will see a notification." 
                    : "Pending task created. They will get the task when they sign up.",
                error: nil
            )
            
            print("✅ GameSettingsService: Assignment successful")
            print("   Task ID: \(response)")
            print("   User Exists: \(userExists)")
            
            return successResponse
            
        } catch {
            print("❌ GameSettingsService: Assignment failed with error: \(error)")
            
            let errorMessage: String
            if let dbError = error as? PostgrestError {
                errorMessage = dbError.message
            } else {
                errorMessage = error.localizedDescription
            }
            
            return ExternalRecorderAssignmentResponse(
                success: false,
                taskId: nil,
                userExists: false,
                message: nil,
                error: errorMessage
            )
        }
    }
    
    /// Removes external recorder assignment from a game
    static func removeExternalRecorder(
        gameId: String,
        partyId: String
    ) async throws -> Bool {
        
        let client = SupabaseManager.shared.client
        
        print("🗑️ GameSettingsService: Removing external recorder assignment")
        print("   Game ID: \(gameId)")
        print("   Party ID: \(partyId)")
        
        do {
            // Remove recorder info from party_games
            try await client
                .from("party_games")
                .update([
                    "recorder_phone": AnyJSON.null,
                    "recorder_name": AnyJSON.null
                ])
                .eq("id", value: gameId)
                .execute()
            
            // Remove or cancel any pending tasks for this game
            try await client
                .from("pending_phone_tasks")
                .delete()
                .eq("game_id", value: gameId)
                .execute()
            
            // Delete existing recording tasks for this game
            try await client
                .from("tasks")
                .delete()
                .eq("game_id", value: gameId)
                .eq("task_type", value: "game_recording")
                .execute()
            
            print("✅ GameSettingsService: External recorder assignment removed")
            return true
            
        } catch {
            print("❌ GameSettingsService: Failed to remove assignment: \(error)")
            throw error
        }
    }
    
    /// Updates game title
    static func updateGameTitle(
        gameId: String,
        newTitle: String
    ) async throws -> Bool {
        
        let client = SupabaseManager.shared.client
        
        print("✏️ GameSettingsService: Updating game title")
        print("   Game ID: \(gameId)")
        print("   New Title: \(newTitle)")
        
        do {
            try await client
                .from("party_games")
                .update(["title": newTitle.trimmingCharacters(in: .whitespacesAndNewlines)])
                .eq("id", value: gameId)
                .execute()
            
            print("✅ GameSettingsService: Game title updated successfully")
            return true
            
        } catch {
            print("❌ GameSettingsService: Failed to update title: \(error)")
            throw error
        }
    }
    
    /// Deletes a game permanently
    static func deleteGame(
        gameId: String
    ) async throws -> Bool {
        
        let client = SupabaseManager.shared.client
        
        print("🗑️ GameSettingsService: Deleting game")
        print("   Game ID: \(gameId)")
        
        do {
            // Delete the game (cascade should handle related records)
            try await client
                .from("party_games")
                .delete()
                .eq("id", value: gameId)
                .execute()
            
            print("✅ GameSettingsService: Game deleted successfully")
            return true
            
        } catch {
            print("❌ GameSettingsService: Failed to delete game: \(error)")
            throw error
        }
    }
}

// MARK: - Game Settings Errors
enum GameSettingsError: LocalizedError {
    case userNotAuthenticated
    case invalidPhoneNumber
    case gameNotFound
    case permissionDenied
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotAuthenticated:
            return "User not authenticated"
        case .invalidPhoneNumber:
            return "Invalid phone number format"
        case .gameNotFound:
            return "Game not found"
        case .permissionDenied:
            return "Permission denied"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Supporting Models
private struct UserProfile: Codable {
    let id: String
    let full_name: String?
}

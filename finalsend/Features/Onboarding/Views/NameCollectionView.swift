import SwiftUI
import Supabase

struct NameCollectionView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    let phoneNumber: String
    let fromInvite: Bool
    let invitePartyId: String?
    let invitePartyName: String?
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case firstName
        case lastName
    }
    
    var body: some View {
        ZStack {
            Color.neutralBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Header
                VStack(spacing: 16) {
                    Text("What's your name?")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.primary)
                    
                    if fromInvite, let partyName = invitePartyName {
                        Text("Help your friends recognize you in \(partyName)")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("Help your friends recognize you in parties")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(.horizontal, 20)
                
                // Name form
                VStack(spacing: 20) {
                    // First name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("First Name")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.primary)
                        
                        TextField("Enter your first name", text: $firstName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .firstName)
                            .textContentType(.givenName)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                    
                    // Last name field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Name")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.primary)
                        
                        TextField("Enter your last name", text: $lastName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .focused($focusedField, equals: .lastName)
                            .textContentType(.familyName)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                }
                .padding(.horizontal, 20)
                
                // Continue button
                Button(action: handleContinue) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text(fromInvite ? "Join Party" : "Continue")
                                .font(.headline.weight(.semibold))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(isFormValid ? Color.brandBlue : Color.gray.opacity(0.3))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading || !isFormValid)
                .padding(.horizontal, 20)
                
                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .navigationBarItems(
            leading: Button("Back") {
                dismiss()
            }
            .font(.callout.weight(.medium))
            .foregroundColor(.brandBlue)
            .disabled(isLoading)
        )
        .onAppear {
            focusedField = .firstName
        }
    }
    
    private var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleContinue() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Update the user's profile with their name
                try await updateUserProfile()
                
                await MainActor.run {
                    isLoading = false
                    
                    // Clear the name collection flag
                    authManager.needsNameCollection = false
                    authManager.pendingPhoneNumber = ""
                    
                    if fromInvite, let partyId = invitePartyId {
                        // User came from an invite, navigate directly to the party
                        print("✅ Name collection completed, navigating to party: \(partyId)")
                        AppNavigator.shared.navigateToParty(partyId)
                    } else {
                        // User came from regular signup, let AuthManager handle navigation
                        print("✅ Name collection completed, navigating to dashboard")
                        
                        // Force MainTabView to refresh and show UI
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: Notification.Name("nameCollectionCompleted"), object: nil)
                        }
                    }
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save your name. Please try again."
                    isLoading = false
                }
            }
        }
    }
    
    private func updateUserProfile() async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "NameCollection", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Convert string to UUID for proper database comparison
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "NameCollection", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        
        let fullName = "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
        
        // Update the profile with the user's name
        try await SupabaseManager.shared.client
            .from("profiles")
            .update(["full_name": fullName])
            .eq("id", value: userIdUUID)
            .execute()
        
        print("✅ User profile updated with name: \(fullName)")
        
        // Update the auth user's metadata with the name (like phone update feature)
        try await updateAuthUserMetadata(fullName: fullName)
    }
    
    private func updateAuthUserMetadata(fullName: String) async throws {
        // Update the user's metadata in auth.users table
        let metadata: [String: AnyJSON] = [
            "full_name": AnyJSON.string(fullName),
            "phone": AnyJSON.string(phoneNumber)
        ]
        
        // Use the same pattern as the phone update feature
        try await SupabaseManager.shared.client.auth.update(user: UserAttributes(
            data: metadata
        ))
        
        print("✅ Auth user metadata updated with name: \(fullName)")
    }
    

}

#Preview {
    NavigationView {
        NameCollectionView(
            phoneNumber: "(555) 123-4567",
            fromInvite: false,
            invitePartyId: nil,
            invitePartyName: nil
        )
    }
}

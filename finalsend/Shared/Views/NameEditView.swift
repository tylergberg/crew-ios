import SwiftUI
import Supabase

struct NameEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    let currentName: String?
    let onNameUpdated: (String) -> Void
    
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
        NavigationView {
            ZStack {
                Color.neutralBackground.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Edit Your Name")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                        
                        Text("Update how your name appears to other users")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
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
                    
                    // Save button
                    Button(action: handleSave) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Save Changes")
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
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .font(.callout.weight(.medium))
                .foregroundColor(.brandBlue)
                .disabled(isLoading),
                trailing: Button("Save") {
                    handleSave()
                }
                .font(.callout.weight(.medium))
                .foregroundColor(isFormValid ? .brandBlue : .gray)
                .disabled(isLoading || !isFormValid)
            )
            .onAppear {
                setupInitialName()
                focusedField = .firstName
            }
        }
    }
    
    private var isFormValid: Bool {
        return !firstName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               !lastName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func setupInitialName() {
        if let currentName = currentName, !currentName.isEmpty && currentName != "unknown" {
            // Parse existing name into first and last name
            let nameComponents = currentName.components(separatedBy: " ")
            if nameComponents.count >= 2 {
                firstName = nameComponents[0]
                lastName = nameComponents.dropFirst().joined(separator: " ")
            } else {
                firstName = currentName
                lastName = ""
            }
        }
    }
    
    private func handleSave() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let fullName = "\(firstName.trimmingCharacters(in: .whitespacesAndNewlines)) \(lastName.trimmingCharacters(in: .whitespacesAndNewlines))"
                
                // Update the user's profile with their name
                try await updateUserProfile(fullName: fullName)
                
                // Update the auth user's metadata with the name
                try await updateAuthUserMetadata(fullName: fullName)
                
                await MainActor.run {
                    isLoading = false
                    onNameUpdated(fullName)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save your name. Please try again."
                    isLoading = false
                }
            }
        }
    }
    
    private func updateUserProfile(fullName: String) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "NameEdit", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Convert string to UUID for proper database comparison
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "NameEdit", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        
        // Update the profile with the user's name
        try await SupabaseManager.shared.client
            .from("profiles")
            .update(["full_name": fullName])
            .eq("id", value: userIdUUID)
            .execute()
        
        print("✅ User profile updated with name: \(fullName)")
    }
    
    private func updateAuthUserMetadata(fullName: String) async throws {
        // Update the user's metadata in auth.users table
        let metadata: [String: AnyJSON] = [
            "full_name": AnyJSON.string(fullName)
        ]
        
        // Use the same pattern as the phone update feature
        try await SupabaseManager.shared.client.auth.update(user: UserAttributes(
            data: metadata
        ))
        
        print("✅ Auth user metadata updated with name: \(fullName)")
    }
}

#Preview {
    NameEditView(
        currentName: "John Doe",
        onNameUpdated: { _ in }
    )
}



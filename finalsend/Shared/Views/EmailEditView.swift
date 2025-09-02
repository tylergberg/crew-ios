import SwiftUI
import Supabase

struct EmailEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authManager = AuthManager.shared
    
    let currentEmail: String?
    let onEmailUpdated: (String) -> Void
    
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.neutralBackground.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Text("Edit Your Email")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.primary)
                        
                        Text("Update your email address for account notifications")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 20)
                    
                    // Email form
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email Address")
                                .font(.callout.weight(.medium))
                                .foregroundColor(.primary)
                            
                            TextField("Enter your email address", text: $email)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .focused($isEmailFocused)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                                .onChange(of: email) { _ in
                                    errorMessage = ""
                                }
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
                setupInitialEmail()
                isEmailFocused = true
            }
        }
    }
    
    private var isFormValid: Bool {
        return !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               isValidEmail(email)
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func setupInitialEmail() {
        if let currentEmail = currentEmail, !currentEmail.isEmpty {
            email = currentEmail
        }
    }
    
    private func handleSave() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Update the user's profile with their email
                try await updateUserProfile(email: trimmedEmail)
                
                // Update the auth user's email (this will trigger email verification)
                try await updateAuthUserEmail(email: trimmedEmail)
                
                await MainActor.run {
                    isLoading = false
                    onEmailUpdated(trimmedEmail)
                    dismiss()
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save your email. Please try again."
                    isLoading = false
                }
            }
        }
    }
    
    private func updateUserProfile(email: String) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw NSError(domain: "EmailEdit", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        
        // Convert string to UUID for proper database comparison
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "EmailEdit", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        
        // Update the profile with the user's email
        try await SupabaseManager.shared.client
            .from("profiles")
            .update(["email": email])
            .eq("id", value: userIdUUID)
            .execute()
        
        print("✅ User profile updated with email: \(email)")
    }
    
    private func updateAuthUserEmail(email: String) async throws {
        // Update the user's email in auth.users table
        // This will trigger email verification if the email is different
        try await SupabaseManager.shared.client.auth.update(user: UserAttributes(
            email: email
        ))
        
        print("✅ Auth user email updated: \(email)")
    }
}

#Preview {
    EmailEditView(
        currentEmail: "john.doe@example.com",
        onEmailUpdated: { _ in }
    )
}



//
//  SignupView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import SwiftUI
import Supabase

struct SignupView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var fullName = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showConfirmation = false
    @State private var fromInvite = false
    @State private var invitePartyId: String?
    @State private var invitePartyName: String?
    
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case email, password, confirmPassword, fullName
    }
    
    var body: some View {
        ZStack {
            Color.neutralBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                Image("crew-wordmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                
                VStack(spacing: 8) {
                    Text(fromInvite ? "Join to Enter the Party" : "Join Now")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.titleDark)
                        .multilineTextAlignment(.center)
                }
                
                // Invite Info Card
                if fromInvite, let partyName = invitePartyName {
                    VStack(spacing: 8) {
                        Text("You're signing up to join")
                            .font(.footnote.weight(.medium))
                            .foregroundColor(.titleDark)
                        
                        Text(partyName)
                            .font(.callout.weight(.bold))
                            .foregroundColor(.brandBlue)
                        
                        Text("You'll be added to the party automatically after confirming your email")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(Radius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.button)
                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                
                VStack(spacing: 16) {
                    // Full Name Field
                    TextField("Full Name", text: $fullName)
                        .textContentType(.name)
                        .foregroundColor(.titleDark)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .fullName)
                    
                    // Email Field
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .autocorrectionDisabled(true)
                        .foregroundColor(.titleDark)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .email)
                    
                    // Password Field
                    SecureField("Password", text: $password)
                        .textContentType(.newPassword)
                        .foregroundColor(.titleDark)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .password)
                    
                    // Password Requirements
                    VStack(alignment: .leading, spacing: 4) {
                        PasswordRequirementRow(
                            text: "At least 8 characters",
                            isValid: password.count >= 8
                        )
                        PasswordRequirementRow(
                            text: "Contains a number",
                            isValid: password.range(of: "\\d", options: .regularExpression) != nil
                        )
                        PasswordRequirementRow(
                            text: "Contains a special character",
                            isValid: password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
                        )
                    }
                    .padding(.leading, 8)
                    
                    // Confirm Password Field
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textContentType(.newPassword)
                        .foregroundColor(.titleDark)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .confirmPassword)
                    
                    if !confirmPassword.isEmpty {
                        HStack {
                            Image(systemName: passwordsMatch ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(passwordsMatch ? .green : .red)
                            Text(passwordsMatch ? "Passwords match" : "Passwords do not match")
                                .font(.caption)
                                .foregroundColor(passwordsMatch ? .green : .red)
                        }
                        .padding(.leading, 8)
                    }
                    
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal)
                
                Button(action: handleSignup) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .titleDark))
                    } else {
                        Text("JOIN NOW")
                            .font(Typography.button().weight(.bold))
                            .foregroundColor(.titleDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.yellow)
                            .cornerRadius(Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.button)
                                    .stroke(Color.outlineBlack, lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                    }
                }
                .disabled(isLoading || !isFormValid)
                .padding(.horizontal)
                
                Spacer()
                
                HStack {
                    Text("Already have an account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    NavigationLink("Login") {
                        LoginView()
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundColor(.brandBlue)
                }
            }
            .padding()
        }
        .onAppear {
            checkForInviteData()
        }
        .sheet(isPresented: $showConfirmation) {
            SignupConfirmationView(
                email: email,
                name: fullName,
                fromInvite: fromInvite,
                invitePartyId: invitePartyId,
                invitePartyName: invitePartyName
            )
        }
    }
    
    // MARK: - Computed Properties
    
    private var passwordsMatch: Bool {
        return password == confirmPassword && !password.isEmpty
    }
    
    private var isPasswordValid: Bool {
        let hasMinLength = password.count >= 8
        let hasNumber = password.range(of: "\\d", options: .regularExpression) != nil
        let hasSpecialChar = password.range(of: "[!@#$%^&*(),.?\":{}|<>]", options: .regularExpression) != nil
        return hasMinLength && hasNumber && hasSpecialChar
    }
    
    private var isFormValid: Bool {
        return !email.isEmpty && 
               !fullName.isEmpty && 
               isPasswordValid && 
               passwordsMatch
    }
    
    // MARK: - Methods
    
    private func checkForInviteData() {
        // Check for pending invite data from AuthManager
        if let token = authManager.pendingInviteToken {
            fromInvite = true
            invitePartyId = token
            // You might want to fetch party name from the token
        }
    }
    
    private func handleSignup() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                let client = SupabaseManager.shared.client
                
                // Store invite data if coming from invite (AuthManager already handles this)
                if fromInvite, let partyId = invitePartyId {
                    print("🔍 SignupView: Storing invite token for signup flow: \(partyId)")
                    // The token is already stored in UserDefaults from Universal Link
                }
                
                // Create user with Supabase
                let signUpResponse = try await client.auth.signUp(
                    email: email,
                    password: password,
                    data: ["full_name": AnyJSON.string(fullName)]
                )
                
                await MainActor.run {
                    let user = signUpResponse.user
                    if user.identities?.isEmpty == false {
                        // User created successfully
                        showConfirmation = true
                    } else {
                        errorMessage = "An account with this email already exists. Please sign in instead."
                    }
                    isLoading = false
                }
                
            } catch {
                await MainActor.run {
                    let errorMessage = error.localizedDescription
                    if errorMessage.contains("already registered") || errorMessage.contains("already exists") {
                        self.errorMessage = "An account with this email already exists. Please sign in instead."
                    } else {
                        self.errorMessage = "Signup failed. Please try again."
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct PasswordRequirementRow: View {
    let text: String
    let isValid: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: isValid ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isValid ? .green : .secondary)
                .font(.system(size: 12))
            
            Text(text)
                .font(.caption)
                .foregroundColor(isValid ? .green : .secondary)
        }
    }
}

#Preview {
    SignupView()
}

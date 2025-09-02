//
//  LoginView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import Foundation
import SwiftUI
import Supabase

struct LoginView: View {
    @StateObject private var authManager = AuthManager.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email, password
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

                Text("Login")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.titleDark)
                
                // Show message if there's a pending invite
                if UserDefaults.standard.string(forKey: "pending_invite_token") != nil {
                    Text("🎉 You're joining a party!")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(Color.brandBlue)
                        .cornerRadius(20)
                }

                VStack(spacing: 16) {
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

                    SecureField("Password", text: $password)
                        .foregroundColor(.titleDark)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                        .focused($focusedField, equals: .password)

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            print("Navigate to reset password")
                        }
                        .font(.footnote)
                        .foregroundColor(.brandBlue)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    isLoading = true
                    Task {
                        do {
                            let client = SupabaseManager.shared.client
                            let session = try await client.auth.signIn(
                                email: email,
                                password: password
                            )
                            print("Login successful: \(session)")
                            
                            // Persist session to Keychain
                            try await authManager.persistCurrentSession()
                            
                            // Check if there's a pending invite to process
                            if let partyId = await authManager.acceptPendingInviteIfAny() {
                                print("✅ Invite accepted after login, navigating to party: \(partyId)")
                                AppNavigator.shared.navigateToParty(partyId)
                            } else {
                                print("🔍 No pending invite, navigating to dashboard")
                                AppNavigator.shared.navigateToDashboard()
                            }
                            
                        } catch {
                            print("Login failed: \(error.localizedDescription)")
                        }
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("LOGIN")
                            .font(Typography.button().weight(.bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#353E3E"))
                            .cornerRadius(Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.button)
                                    .stroke(Color.outlineBlack, lineWidth: 1.5)
                            )
                            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal)

                Spacer()
            }
            .padding()
        }
        .onAppear {
            // Prefill email if available from Universal Link
            if let lastEmail = authManager.lastEmail {
                email = lastEmail
            }
        }
    }
}

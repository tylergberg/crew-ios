//
//  LoginView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import Foundation
import SwiftUI
import Supabase

let supabase = SupabaseClient(
    supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
    supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
)

struct LoginView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Field?

    enum Field: Hashable {
        case email, password
    }

    var body: some View {
        ZStack {
            Color(hex: "#9BC8EE")!.ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                Image("finalsendLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)

                Text("Login")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "#401B17")!)

                VStack(spacing: 16) {
                    TextField("Email", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 2))
                        .focused($focusedField, equals: .email)

                    SecureField("Password", text: $password)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(14)
                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black, lineWidth: 2))
                        .focused($focusedField, equals: .password)

                    HStack {
                        Spacer()
                        Button("Forgot password?") {
                            print("Navigate to reset password")
                        }
                        .font(.system(size: 12))
                        .foregroundColor(Color(hex: "#4A81E8")!)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    isLoading = true
                    Task {
                        do {
                            let session = try await supabase.auth.signIn(
                                email: email,
                                password: password
                            )
                            print("Login successful: \(session)")
                            DispatchQueue.main.async {
                                isLoggedIn = true
                            }
                            // TODO: Navigate to dashboard or store session
                        } catch {
                            print("Login failed: \(error.localizedDescription)")
                        }
                        isLoading = false
                    }
                }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    } else {
                        Text("LOGIN")
                            .font(.system(size: 18, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color(hex: "#F9C94E")!)
                            .cornerRadius(18)
                            .shadow(color: .black, radius: 0, x: 4, y: 4)
                    }
                }
                .disabled(isLoading)
                .padding(.horizontal)

                Spacer()

                Button(action: {
                    print("Navigate to SignupView")
                }) {
                    Text("Don't have an account? Join Now")
                        .font(.system(size: 14))
                        .foregroundColor(Color(hex: "#401B17")!)
                        .underline()
                }

                Spacer()
            }
            .padding()
        }
    }
}

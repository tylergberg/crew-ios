//
//  IndexView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-29.
//

import SwiftUI

struct ScaleOnPressButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 1.05 : 1.0)
            .offset(y: configuration.isPressed ? -4 : 0)
            .shadow(color: .black.opacity(0.12), radius: configuration.isPressed ? 6 : 3, x: 0, y: configuration.isPressed ? 6 : 3)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct IndexView: View {
    var body: some View {
        NavigationStack {
                ZStack {
                    // Background
                    Color.neutralBackground.ignoresSafeArea()

                    VStack(spacing: 24) {
                        // Logo
                        Image("crew-wordmark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)

                        // Buttons
                                    VStack(spacing: 16) {
                // Single "Get started" button - styled to match app design
                NavigationLink(destination: PhoneAuthView()) {
                    Text("Get started")
                        .font(Typography.button().weight(.bold))
                        .foregroundColor(.white)
                        .frame(width: 280, height: 64)
                        .background(Color(hex: "#353E3E"))
                        .cornerRadius(Radius.button)
                        .shadow(color: .black.opacity(0.12), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(ScaleOnPressButtonStyle())
                
                // Legal disclaimer
                Text("By tapping 'Get started', you agree to our Privacy Policy and Terms of Service")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
                    }
                }
                .overlay(
                    VStack {
                        Spacer()
                        NavigationLink(destination: LoginView()) {
                            Text("Login with email")
                                .font(.callout.weight(.medium))
                                .foregroundColor(.brandBlue)
                                .underline()
                        }
                        .padding(.bottom, 40)
                    }
                )
        }

    }
}

#Preview {
    IndexView()
}

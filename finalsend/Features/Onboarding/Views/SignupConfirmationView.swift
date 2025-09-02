//
//  SignupConfirmationView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-14.
//

import SwiftUI

struct SignupConfirmationView: View {
    let email: String
    let name: String
    let fromInvite: Bool
    let invitePartyId: String?
    let invitePartyName: String?
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            Color.neutralBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                
                // Email Icon
                VStack(spacing: 16) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.brandBlue)
                        .frame(width: 80, height: 80)
                        .background(Color.white)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.brandBlue.opacity(0.3), lineWidth: 2)
                        )
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    
                    Text("Check your email")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.titleDark)
                        .multilineTextAlignment(.center)
                }
                
                // Email Info
                VStack(spacing: 16) {
                    Text("We've sent a verification link to")
                        .font(.body)
                        .foregroundColor(.titleDark)
                        .multilineTextAlignment(.center)
                    
                    Text(email)
                        .font(.callout.weight(.bold))
                        .foregroundColor(.titleDark)
                        .multilineTextAlignment(.center)
                }
                
                // Invite Info
                if fromInvite, let partyName = invitePartyName {
                    VStack(spacing: 12) {
                        Text("After verifying your email, you'll be automatically added to")
                            .font(.footnote)
                            .foregroundColor(.titleDark)
                            .multilineTextAlignment(.center)
                        
                        Text(partyName)
                            .font(.callout.weight(.bold))
                            .foregroundColor(.brandBlue)
                            .multilineTextAlignment(.center)
                    }
                    .padding(20)
                    .background(Color.white)
                    .cornerRadius(Radius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.button)
                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                }
                
                // Instructions
                VStack(spacing: 12) {
                    Text("Click the link in your email to verify your account.")
                        .font(.footnote)
                        .foregroundColor(.titleDark)
                        .multilineTextAlignment(.center)
                    
                    Text("Don't see it? Check your spam folder or try again in a few minutes.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 16) {
                    Button(action: {
                        // Open email app
                        if let url = URL(string: "message://") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Image(systemName: "envelope")
                            Text("Open Email App")
                        }
                        .font(Typography.button().weight(.semibold))
                        .foregroundColor(.titleDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Color.yellow)
                        .cornerRadius(Radius.button)
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.button)
                                .stroke(Color.outlineBlack, lineWidth: 1.5)
                        )
                        .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                    }
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Back to Login")
                            .font(.callout.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(32)
        }
    }
}

#Preview {
    SignupConfirmationView(
        email: "test@example.com",
        name: "John Doe",
        fromInvite: true,
        invitePartyId: "123",
        invitePartyName: "Bachelor Party 2024"
    )
}





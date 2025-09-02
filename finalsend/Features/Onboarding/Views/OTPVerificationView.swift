import SwiftUI
import Supabase

struct OTPVerificationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var phoneAuthService = PhoneAuthService.shared
    @StateObject private var authManager = AuthManager.shared
    
    let phoneNumber: String
    let fromInvite: Bool
    let invitePartyId: String?
    let invitePartyName: String?
    let isNewUser: Bool
    
    @State private var otpCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var timeRemaining = 60
    @State private var canResend = false
    @State private var showNameCollection = false
    @FocusState private var isOTPFieldFocused: Bool
    

    
    var body: some View {
        ZStack {
            Color.neutralBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                

                
                VStack(spacing: 8) {
                    Text("Verify your phone")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.titleDark)
                    
                    Text("Enter the 6-digit code sent to \(phoneNumber)")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 16) {
                    // OTP Input Field - styled to match app design
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("Enter 6-digit code", text: $otpCode)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.titleDark)
                            .keyboardType(.numberPad)
                            .textContentType(.none) // Disable all autofill to remove the bar completely
                            .multilineTextAlignment(.center)
                            .background(Color.clear)
                            .ignoresSafeArea(.keyboard, edges: .bottom)
                            .focused($isOTPFieldFocused)
                            .onChange(of: otpCode) { newValue in
                                // Limit to 6 digits and only allow numbers
                                let filtered = newValue.filter { $0.isNumber }
                                if filtered.count <= 6 {
                                    otpCode = filtered
                                } else {
                                    otpCode = String(filtered.prefix(6))
                                }
                                errorMessage = ""
                                
                                // Auto-submit when 6 digits are entered
                                if filtered.count == 6 && isFormValid {
                                    handleVerifyOTP()
                                }
                            }
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(Radius.button)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.button)
                                    .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 20)
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    
                    // Verify Button
                    Button(action: handleVerifyOTP) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .titleDark))
                                .scaleEffect(1.2)
                        } else {
                            Text("Verify code")
                                .font(Typography.button().weight(.bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(isFormValid ? Color(hex: "#353E3E") : Color.gray.opacity(0.3))
                                .cornerRadius(Radius.button)
                                .overlay(
                                    RoundedRectangle(cornerRadius: Radius.button)
                                        .stroke(isFormValid ? Color.outlineBlack : Color.clear, lineWidth: 1.5)
                                )
                                .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                        }
                    }
                    .disabled(isLoading || !isFormValid)
                    .padding(.horizontal, 20)
                    
                    // Resend Code Section
                    VStack(spacing: 8) {
                        if canResend {
                            Button(action: handleResendOTP) {
                                Text("Resend code")
                                    .font(.callout.weight(.medium))
                                    .foregroundColor(.brandBlue)
                                    .underline()
                            }
                        } else {
                            Text("Resend code in \(timeRemaining)s")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)

        .onAppear {
            startTimer()
            // Auto-focus the OTP field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isOTPFieldFocused = true
            }
        }

    }
    
    private var isFormValid: Bool {
        return otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }
    
    private func handleVerifyOTP() {
        guard isFormValid else { return }
        
        print("🔍 Starting OTP verification...")
        isLoading = true
        errorMessage = ""
        

        
        Task {
            do {
                print("🔍 Calling phoneAuthService.verifyOTP...")
                // Unified verification - handles both new and existing users automatically
                let session = try await phoneAuthService.verifyOTP(phoneNumber: phoneNumber, otp: otpCode)
                
                print("🔍 OTP verification succeeded, persisting session...")
                // Persist session
                try await authManager.persistCurrentSession()
                
                // Check if user profile exists and has a proper name
                let userProfile = await phoneAuthService.getUserProfile(userId: session.user.id.uuidString)
                let hasProperName = userProfile?.full_name != nil && userProfile?.full_name != "New User"
                print("🔍 User profile exists: \(userProfile != nil)")
                print("🔍 User has proper name: \(hasProperName)")
                print("🔍 User name: \(userProfile?.full_name ?? "nil")")
                
                // Update the phone number in the profile table
                try await phoneAuthService.updatePhoneNumberInProfile(phoneNumber)
                
                print("🔍 About to run MainActor block...")
                await MainActor.run {
                    print("🔍 Inside MainActor block, setting isLoading = false")
                    isLoading = false
                    
                    if !hasProperName {
                        // For new users or users with default names, set flag to show name collection
                        authManager.needsNameCollection = true
                        authManager.pendingPhoneNumber = phoneNumber
                        print("✅ OTP verification completed, setting needsNameCollection flag for user without proper name")
                    } else {
                        // For existing users with proper names, let AuthManager session listener handle navigation
                        print("✅ OTP verification completed, existing user with proper name - waiting for session listener to handle navigation")
                    }
                }
                
            } catch let error as PhoneAuthError {
                print("❌ PhoneAuthError caught: \(error)")
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                print("❌ Unexpected error caught: \(error)")
                await MainActor.run {
                    errorMessage = "An unexpected error occurred. Please try again."
                    isLoading = false
                }
            }
        }
    }
    
    private func handleResendOTP() {
        Task {
            do {
                try await phoneAuthService.sendOTP(to: phoneNumber)
                startTimer()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    private func startTimer() {
        timeRemaining = 60
        canResend = false
        
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                canResend = true
                timer.invalidate()
            }
        }
    }
    

}

#Preview {
    OTPVerificationView(
        phoneNumber: "(555) 123-4567",
        fromInvite: false,
        invitePartyId: nil,
        invitePartyName: nil,
        isNewUser: false
    )
}


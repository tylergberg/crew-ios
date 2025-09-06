import SwiftUI
import Supabase

struct PhoneAuthView: View {
    @StateObject private var phoneAuthService = PhoneAuthService.shared
    @StateObject private var authManager = AuthManager.shared
    
    @State private var phoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showOTPVerification = false
    @State private var fromInvite = false
    @State private var invitePartyId: String?
    @State private var invitePartyName: String?
    @State private var isNewUser = false // Will be determined automatically
    @FocusState private var isPhoneFieldFocused: Bool
    

    
    var body: some View {
        ZStack {
            Color.neutralBackground.ignoresSafeArea()
            
            VStack(spacing: 32) {
                Spacer()
                

                
                VStack(spacing: 8) {
                    Text("Enter your phone number")
                        .font(.title2.weight(.bold))
                        .foregroundColor(.titleDark)
                }
                
                VStack(spacing: 16) {
                    // Phone Number Input - styled to match app design
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("+1")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.titleDark)
                                .padding(.leading, 16)
                            
                            TextField("Phone number", text: $phoneNumber)
                                .font(.system(size: 16))
                                .foregroundColor(.titleDark)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .background(Color.clear)
                                .focused($isPhoneFieldFocused)
                                .onChange(of: phoneNumber) { newValue in
                                    // Simple validation - just clear error message
                                    errorMessage = ""
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
                    
                    // Send OTP Button
                    Button(action: handleSendOTP) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .titleDark))
                                .scaleEffect(1.2)
                        } else {
                            Text("Send code")
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
                    
                    // Consent text
                    Text("By tapping SEND CODE, you consent to receive text messages from us or event hosts. Text HELP for help and STOP to cancel.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
            }
        }
        .navigationBarBackButtonHidden(false)
        .fullScreenCover(isPresented: $showOTPVerification) {
            OTPVerificationView(
                phoneNumber: phoneNumber,
                fromInvite: fromInvite,
                invitePartyId: invitePartyId,
                invitePartyName: invitePartyName,
                isNewUser: isNewUser
            )
            .transition(.opacity)
            .animation(.easeInOut(duration: 0.3), value: showOTPVerification)
        }
        .onAppear {
            loadInviteData()
            // Auto-focus the phone number field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPhoneFieldFocused = true
            }
        }

    }
    
    private var isFormValid: Bool {
        return phoneAuthService.validatePhoneNumber(phoneNumber)
    }
    
    private func handleSendOTP() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // Send OTP - we'll determine if user is new during verification
                _ = try await phoneAuthService.sendOTP(to: phoneNumber)
                
                await MainActor.run {
                    // We'll determine if user is new during OTP verification
                    isNewUser = false // This will be overridden during verification
                    print("🔍 OTP sent, will determine user status during verification")
                    isLoading = false
                    showOTPVerification = true
                }
                
            } catch let error as PhoneAuthError {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "An unexpected error occurred. Please try again."
                    isLoading = false
                }
            }
        }
    }
    
    private func loadInviteData() {
        // Check for pending invite token from AuthManager
        if let token = authManager.pendingInviteToken {
            invitePartyId = token
            fromInvite = true
            print("🔍 PhoneAuthView: Found pending invite token: \(token)")
        }
    }
}

#Preview {
    NavigationView {
        PhoneAuthView()
    }
}

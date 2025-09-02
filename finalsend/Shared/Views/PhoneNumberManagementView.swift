import SwiftUI
import Supabase

struct PhoneNumberManagementView: View {
    @StateObject private var phoneAuthService = PhoneAuthService.shared
    @StateObject private var authManager = AuthManager.shared
    
    let currentProfilePhone: String?
    let onPhoneUpdated: (String) -> Void
    let currentPhone: String? // Pass the phone from profile
    
    @State private var newPhoneNumber = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var showOTPVerification = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        let _ = print("🔍 PhoneNumberManagementView - currentProfilePhone: \(currentProfilePhone ?? "nil")")
        return NavigationView {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Phone Number Display (if connected)
                    if let currentPhone = currentProfilePhone, !currentPhone.isEmpty {
                        SharedProfileSection(title: "") {
                            HStack {
                                Image(systemName: "phone.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(Color.finalSendBlue)
                                    .frame(width: 24)
                                
                                Spacer()
                                
                                Text(phoneAuthService.formatPhoneNumber(currentPhone ?? ""))
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.black)
                                
                                Spacer()
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.system(size: 16))
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                    } else {
                        // Phone Number Input (if not connected)
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Enter your phone number", text: $newPhoneNumber)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: "#401B17")!)
                                .keyboardType(.phonePad)
                                .textContentType(.telephoneNumber)
                                .padding()
                                .background(Color(hex: "#F8F9FA")!)
                                .cornerRadius(12)
                                .onChange(of: newPhoneNumber) { _ in
                                    errorMessage = ""
                                }
                            
                            if !newPhoneNumber.isEmpty && !phoneAuthService.validatePhoneNumber(newPhoneNumber) {
                                Text("Please enter a valid phone number")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        // Error Message
                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Send Verification Code Button
                        Button(action: handleSendVerification) {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#401B17")!))
                                        .scaleEffect(0.8)
                                } else {
                                    Text("Send Verification Code")
                                        .font(.system(size: 18, weight: .bold, design: .serif))
                                }
                            }
                            .foregroundColor(isFormValid ? Color(hex: "#401B17")! : Color(hex: "#5B626B")!)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(isFormValid ? Color(hex: "#F9C94E")! : Color(hex: "#F1F3F4")!)
                            .cornerRadius(18)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(Color.black, lineWidth: 1.5)
                            )
                            .shadow(color: isFormValid ? .black : .clear, radius: 0, x: 3, y: 3)
                        }
                        .disabled(!isFormValid || isLoading)
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Phone Number")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(hex: "#401B17")!)
                }
            )
            .sheet(isPresented: $showOTPVerification) {
                PhoneChangeOTPView(
                    phoneNumber: newPhoneNumber,
                    onVerificationSuccess: { verifiedPhone in
                        onPhoneUpdated(verifiedPhone)
                        dismiss()
                    }
                )
            }
        }
    }
    
    private var isFormValid: Bool {
        return phoneAuthService.validatePhoneNumber(newPhoneNumber)
    }
    
    private func handleSendVerification() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                print("📱 Requesting phone update to: \(newPhoneNumber)")
                try await phoneAuthService.requestPhoneUpdate(to: newPhoneNumber)
                
                await MainActor.run {
                    isLoading = false
                    showOTPVerification = true
                    print("✅ Phone update request sent successfully")
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    print("❌ Phone update request failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

struct PhoneChangeOTPView: View {
    @StateObject private var phoneAuthService = PhoneAuthService.shared
    @StateObject private var authManager = AuthManager.shared
    
    let phoneNumber: String
    let onVerificationSuccess: (String) -> Void
    
    @State private var otpCode = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var timeRemaining = 60
    @State private var canResend = false
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.white.ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "phone.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color(hex: "#401B17")!)
                        
                        Text("Verify Your Phone")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .foregroundColor(Color(hex: "#401B17")!)
                        
                        Text("We've sent a verification code to")
                            .font(.system(size: 16, weight: .medium, design: .serif))
                            .foregroundColor(Color(hex: "#401B17")!)
                        
                        Text(phoneAuthService.formatPhoneNumber(phoneNumber))
                            .font(.system(size: 18, weight: .semibold, design: .serif))
                            .foregroundColor(Color(hex: "#401B17")!)
                    }
                    
                    // OTP Input
                    VStack(spacing: 16) {
                        Text("Enter 6-digit code")
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(Color(hex: "#401B17")!)
                        
                        TextField("123456", text: $otpCode)
                            .font(.system(size: 24, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .multilineTextAlignment(.center)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .padding()
                            .background(Color(hex: "#F8F9FA")!)
                            .cornerRadius(12)
                            .onChange(of: otpCode) { newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    otpCode = String(newValue.prefix(6))
                                }
                                errorMessage = ""
                            }
                    }
                    
                    // Error Message
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 14, weight: .medium, design: .serif))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    // Timer and Resend
                    VStack(spacing: 8) {
                        if timeRemaining > 0 {
                            Text("Resend code in \(timeRemaining)s")
                                .font(.system(size: 14, weight: .medium, design: .serif))
                                .foregroundColor(Color(hex: "#401B17")!.opacity(0.7))
                        } else {
                            Button("Resend Code") {
                                handleResendOTP()
                            }
                            .font(.system(size: 16, weight: .semibold, design: .serif))
                            .foregroundColor(Color(hex: "#401B17")!)
                            .disabled(!canResend)
                        }
                    }
                    
                    Spacer()
                    
                    // Verify Button
                    Button(action: handleVerifyOTP) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "#401B17")!))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Verify Phone Number")
                                    .font(.system(size: 18, weight: .bold, design: .serif))
                            }
                        }
                        .foregroundColor(isFormValid ? Color(hex: "#401B17")! : Color(hex: "#5B626B")!)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isFormValid ? Color(hex: "#F9C94E")! : Color(hex: "#F1F3F4")!)
                        .cornerRadius(18)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(Color.black, lineWidth: 1.5)
                        )
                        .shadow(color: isFormValid ? .black : .clear, radius: 0, x: 3, y: 3)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.horizontal, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
                .font(.system(size: 16, weight: .medium, design: .serif))
                .foregroundColor(Color(hex: "#401B17")!)
                .disabled(isLoading)
            )
            .onAppear {
                startTimer()
            }
        }
    }
    
    private var isFormValid: Bool {
        return otpCode.count == 6 && otpCode.allSatisfy { $0.isNumber }
    }
    
    private func handleVerifyOTP() {
        guard isFormValid else { return }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                print("🔐 Verifying phone update for: \(phoneNumber)")
                try await phoneAuthService.verifyPhoneUpdate(phoneNumber: phoneNumber, otp: otpCode)
                
                await MainActor.run {
                    isLoading = false
                    onVerificationSuccess(phoneNumber)
                    print("✅ Phone number updated successfully")
                }
                
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                    print("❌ Phone verification failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func handleResendOTP() {
        Task {
            do {
                try await phoneAuthService.requestPhoneUpdate(to: phoneNumber)
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
    PhoneNumberManagementView(
        currentProfilePhone: nil,
        onPhoneUpdated: { _ in },
        currentPhone: nil
    )
}

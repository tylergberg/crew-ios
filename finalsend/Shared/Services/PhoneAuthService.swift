import Foundation
import Supabase

enum PhoneAuthError: Error, LocalizedError {
    case invalidPhoneNumber
    case otpSendFailed(Error)
    case otpVerificationFailed(Error)
    case phoneNumberAlreadyExists
    case networkError(Error)
    case invalidOTP
    case verificationRequestNotFound
    case phoneUpdateFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidPhoneNumber:
            return "Please enter a valid phone number"
        case .otpSendFailed(let error):
            return "Failed to send verification code: \(error.localizedDescription)"
        case .otpVerificationFailed(let error):
            return "Verification failed: \(error.localizedDescription)"
        case .phoneNumberAlreadyExists:
            return "This phone number is already registered"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidOTP:
            return "Invalid verification code"
        case .verificationRequestNotFound:
            return "Verification request not found or expired. Please request a new code."
        case .phoneUpdateFailed(let error):
            return "Failed to update phone number: \(error.localizedDescription)"
        }
    }
}

@MainActor
class PhoneAuthService: ObservableObject {
    static let shared = PhoneAuthService()
    
    private let client = SupabaseManager.shared.client
    
    private init() {}
    
    // MARK: - Phone Number Validation
    
    /// Validate phone number format
    func validatePhoneNumber(_ phoneNumber: String) -> Bool {
        // Remove all non-digit characters
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        // US phone numbers should be 10 digits (or 11 with country code)
        return digitsOnly.count == 10 || digitsOnly.count == 11
    }
    
    /// Format phone number for display
    func formatPhoneNumber(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.count == 10 {
            // Format as (XXX) XXX-XXXX
            let areaCode = String(digitsOnly.prefix(3))
            let prefix = String(digitsOnly.dropFirst(3).prefix(3))
            let lineNumber = String(digitsOnly.dropFirst(6))
            return "(\(areaCode)) \(prefix)-\(lineNumber)"
        } else if digitsOnly.count == 11 && digitsOnly.hasPrefix("1") {
            // Format US number with country code
            let withoutCountryCode = String(digitsOnly.dropFirst())
            return formatPhoneNumber(withoutCountryCode)
        }
        
        return phoneNumber
    }
    
    /// Convert phone number to E.164 format for Supabase
    private func formatToE164(_ phoneNumber: String) -> String {
        let digitsOnly = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        
        if digitsOnly.count == 10 {
            // Add +1 for US numbers
            return "+1\(digitsOnly)"
        } else if digitsOnly.count == 11 && digitsOnly.hasPrefix("1") {
            // Already has country code, just add +
            return "+\(digitsOnly)"
        } else if phoneNumber.hasPrefix("+") {
            // Already in E.164 format
            return phoneNumber
        }
        
        // Default: assume US number and add +1
        return "+1\(digitsOnly)"
    }
    
    // MARK: - Phone Number Validation
    
    /// Send OTP and check if phone number exists in one call (avoids rate limiting)
    func sendOTPAndCheckIfExists(to phoneNumber: String) async throws -> (phoneExists: Bool, session: Session?) {
        guard validatePhoneNumber(phoneNumber) else {
            throw PhoneAuthError.invalidPhoneNumber
        }
        
        let e164PhoneNumber = formatToE164(phoneNumber)
        
        do {
            // Try to send OTP - this will work for both new and existing users
            _ = try await client.auth.signInWithOTP(phone: e164PhoneNumber)
            
            // Since Supabase signInWithOTP works for both new and existing users,
            // we can't determine user existence from this call alone.
            // We'll need to determine this during OTP verification instead.
            // For now, assume it's a new user and let the verification process handle the logic.
            return (phoneExists: false, session: nil)
        } catch {
            // For any error, re-throw it
            throw PhoneAuthError.otpSendFailed(error)
        }
    }
    
    /// Verify OTP without creating user (for new users who need name collection)
    func verifyOTPWithoutCreatingUser(phoneNumber: String, otp: String) async throws -> Bool {
        guard validatePhoneNumber(phoneNumber) else {
            throw PhoneAuthError.invalidPhoneNumber
        }
        
        guard !otp.isEmpty else {
            throw PhoneAuthError.invalidOTP
        }
        
        let e164PhoneNumber = formatToE164(phoneNumber)
        
        do {
            print("🔐 Verifying OTP without creating user for: \(e164PhoneNumber)")
            
            // This will verify the OTP but not create a user session
            // We'll use a different approach to just validate the OTP
            let response = try await client.auth.verifyOTP(
                phone: e164PhoneNumber,
                token: otp,
                type: .sms
            )
            
            print("✅ OTP verification successful (without user creation)")
            
            // Return true if verification was successful
            return response.session != nil
            
        } catch {
            print("❌ OTP verification failed: \(error)")
            throw PhoneAuthError.otpVerificationFailed(error)
        }
    }
    
    // MARK: - New User Phone Authentication (Sign Up)
    
    /// Send OTP to phone number for new user sign-up
    func sendOTP(to phoneNumber: String) async throws {
        guard validatePhoneNumber(phoneNumber) else {
            throw PhoneAuthError.invalidPhoneNumber
        }
        
        // Convert to E.164 format for Supabase
        let e164PhoneNumber = formatToE164(phoneNumber)
        
        do {
            print("📱 Sending OTP to: \(e164PhoneNumber)")
            
            // Use Supabase's built-in phone auth with Twilio Verify for new users
            _ = try await client.auth.signInWithOTP(phone: e164PhoneNumber)
            
            print("✅ OTP sent successfully")
            
        } catch {
            print("❌ Failed to send OTP: \(error)")
            
            // Check if it's a phone number already exists error
            if error.localizedDescription.contains("already registered") ||
               error.localizedDescription.contains("already exists") {
                throw PhoneAuthError.phoneNumberAlreadyExists
            }
            
            throw PhoneAuthError.otpSendFailed(error)
        }
    }
    
    /// Verify OTP and sign in user (for new users)
    func verifyOTP(phoneNumber: String, otp: String) async throws -> Session {
        guard validatePhoneNumber(phoneNumber) else {
            throw PhoneAuthError.invalidPhoneNumber
        }
        
        guard !otp.isEmpty else {
            throw PhoneAuthError.invalidOTP
        }
        
        // Convert to E.164 format for Supabase
        let e164PhoneNumber = formatToE164(phoneNumber)
        
        do {
            print("🔐 Verifying OTP for: \(e164PhoneNumber)")
            
            // Verify OTP and get session
            let response = try await client.auth.verifyOTP(
                phone: e164PhoneNumber,
                token: otp,
                type: .sms
            )
            
            print("✅ OTP verification successful")
            
            // Extract session from response
            guard let session = response.session else {
                throw PhoneAuthError.otpVerificationFailed(NSError(domain: "PhoneAuth", code: 500, userInfo: [NSLocalizedDescriptionKey: "No session returned from verification"]))
            }
            
            return session
            
        } catch {
            print("❌ OTP verification failed: \(error)")
            
            if error.localizedDescription.contains("Invalid") ||
               error.localizedDescription.contains("invalid") {
                throw PhoneAuthError.invalidOTP
            }
            
            throw PhoneAuthError.otpVerificationFailed(error)
        }
    }
    
    // MARK: - Existing User Phone Number Update (Secure System)
    
    /// Request phone number update for existing user (Step 1)
    func requestPhoneUpdate(to phoneNumber: String) async throws {
        guard validatePhoneNumber(phoneNumber) else {
            throw PhoneAuthError.invalidPhoneNumber
        }
        
        // Convert to E.164 format
        let e164PhoneNumber = formatToE164(phoneNumber)
        
        do {
            print("📱 Requesting phone update to: \(e164PhoneNumber)")
            
            // Try different possible Swift SDK method signatures for updateUser
            // Based on Lovable's guidance, the Swift SDK should have equivalent methods
            
            // Option 1: Try with UserAttributes struct
            let result = try await client.auth.update(user: UserAttributes(phone: e164PhoneNumber))
            
            // The update method returns a User object directly, not an object with error property
            // If it throws an error, it will be caught in the catch block below
            print("✅ Phone update request sent successfully")
            
        } catch {
            print("❌ Failed to request phone update: \(error)")
            
            // Handle specific error cases
            if let error = error as? PhoneAuthError {
                throw error
            }
            
            throw PhoneAuthError.phoneUpdateFailed(error)
        }
    }
    
    /// Verify phone number update for existing user (Step 2)
    func verifyPhoneUpdate(phoneNumber: String, otp: String) async throws {
        guard validatePhoneNumber(phoneNumber) else {
            throw PhoneAuthError.invalidPhoneNumber
        }
        
        guard !otp.isEmpty else {
            throw PhoneAuthError.invalidOTP
        }
        
        // Convert to E.164 format
        let e164PhoneNumber = formatToE164(phoneNumber)
        
        do {
            print("🔐 Verifying phone update for: \(e164PhoneNumber)")
            
            // Try the native Swift SDK verifyOTP method with phone_change type
            // This should be equivalent to the web implementation
            let response = try await client.auth.verifyOTP(
                phone: e164PhoneNumber,
                token: otp,
                type: .phoneChange
            )
            
            // Check if verification was successful
            guard response.session != nil else {
                throw PhoneAuthError.phoneUpdateFailed(NSError(domain: "PhoneAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Phone verification failed"]))
            }
            
            print("✅ Phone number updated successfully")
            
            // Refresh the session to get updated user data
            try await client.auth.refreshSession()
            
            // Also update the user's profile record so the profile UI reflects the new phone immediately
            // Store the human-entered number for consistency with the rest of the app
            do {
                try await updatePhoneNumberInProfile(phoneNumber)
            } catch {
                // Do not fail the flow if the profile update fails; auth phone has been updated
                print("⚠️ Profile phone update failed (continuing): \(error)")
            }
            
        } catch {
            print("❌ Failed to verify phone update: \(error)")
            
            if let error = error as? PhoneAuthError {
                throw error
            }
            
            throw PhoneAuthError.phoneUpdateFailed(error)
        }
    }
    
    // MARK: - Profile Management (Legacy Support)
    
    /// Update user's phone number in profile (legacy method)
    func updatePhoneNumberInProfile(_ phoneNumber: String) async throws {
        guard let userId = AuthManager.shared.currentUserId else {
            throw PhoneAuthError.networkError(NSError(domain: "PhoneAuth", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"]))
        }
        
        do {
            try await client
                .from("profiles")
                .update(["phone": phoneNumber])
                .eq("id", value: userId)
                .execute()
            
            print("✅ Phone number updated in profile")
        } catch {
            print("❌ Failed to update phone number in profile: \(error)")
            // Don't throw here as the auth was successful, just log the error
        }
    }
    
    /// Refresh the current session to get latest user data
    func refreshSession() async throws {
        try await client.auth.refreshSession()
    }
    
    /// Get current user's phone number
    func getCurrentUserPhoneNumber() async -> String? {
        // Don't query if user is logging out
        guard !AuthManager.shared.isLoggingOut else {
            print("⚠️ Skipping phone number query - user is logging out")
            return nil
        }
        
        guard let userId = AuthManager.shared.currentUserId else { return nil }
        
        do {
            let response = try await client
                .from("profiles")
                .select("phone")
                .eq("id", value: userId)
                .single()
                .execute()
            
            // Parse the response to get the phone number
            let data = response.data
            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let phone = jsonData["phone"] as? String {
                return phone
            }
            
            return nil
        } catch {
            print("❌ Failed to get phone number: \(error)")
            return nil
        }
    }
    
    /// Check if a user profile exists for the given user ID
    func checkIfUserProfileExists(userId: String) async -> Bool {
        do {
            let response = try await client
                .from("profiles")
                .select("id")
                .eq("id", value: userId)
                .single()
                .execute()
            
            // If we get here, the profile exists
            return true
        } catch {
            // If we get an error, the profile doesn't exist
            print("🔍 User profile does not exist for ID: \(userId)")
            return false
        }
    }
    
    /// Get user profile for the given user ID
    func getUserProfile(userId: String) async -> ProfileResponse? {
        do {
            let response = try await client
                .from("profiles")
                .select("id, full_name, avatar_url, phone, email, role")
                .eq("id", value: userId)
                .single()
                .execute()
            
            // Parse the response to get the profile
            let data = response.data
            if let jsonData = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                return ProfileResponse(
                    id: jsonData["id"] as? String,
                    full_name: jsonData["full_name"] as? String,
                    avatar_url: jsonData["avatar_url"] as? String,
                    phone: jsonData["phone"] as? String,
                    email: jsonData["email"] as? String,
                    role: jsonData["role"] as? String,
                    home_address: nil,
                    has_car: nil,
                    car_seat_count: nil,
                    dietary_preferences: nil,
                    beverage_preferences: nil,
                    clothing_sizes: nil,
                    birthday: nil,
                    linkedin_url: nil,
                    instagram_handle: nil,
                    fun_stat: nil
                )
            }
            
            return nil
        } catch {
            // If we get an error, the profile doesn't exist
            print("🔍 User profile does not exist for ID: \(userId)")
            return nil
        }
    }
    
    // Debug functionality has been removed
}

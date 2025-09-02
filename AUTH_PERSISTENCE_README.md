# Auth Persistence Implementation

This document describes the mobile auth persistence implementation for the Final Send iOS app.

## Overview

The implementation provides secure session persistence using Keychain storage, automatic session restoration on app launch, and Universal Links support for magic link authentication.

## Architecture

### Key Components

1. **KeychainStore** (`Shared/Utils/KeychainStore.swift`)
   - Secure storage for Supabase sessions
   - Optional biometry support
   - Error handling for Keychain operations

2. **AuthManager** (`Shared/Managers/AuthManager.swift`)
   - Single source of truth for authentication state
   - Session persistence and restoration
   - Universal Links handling
   - Profile management

3. **SessionManager** (`Shared/Managers/SessionManager.swift`)
   - Backward compatibility wrapper
   - Delegates to AuthManager
   - Maintains existing API for existing code

### Flow

1. **App Launch**: `AuthManager.restoreSessionOnLaunch()` checks Keychain for saved session
2. **Login**: After successful authentication, `AuthManager.persistCurrentSession()` saves to Keychain
3. **Magic Links**: Universal Links trigger `AuthManager.handleAuthCallback(url:)`
4. **Logout**: `AuthManager.logout()` clears Keychain and resets state

## Usage

### Basic Authentication

```swift
// Get the shared AuthManager instance
let authManager = AuthManager.shared

// Check authentication status
if authManager.isAuthenticated {
    // User is logged in
}

// Get current user info
let userId = authManager.currentUserId
let userEmail = authManager.currentUserEmail
```

### Login Flow

```swift
// After successful Supabase authentication
do {
    let session = try await client.auth.signIn(email: email, password: password)
    try await authManager.persistCurrentSession()
} catch {
    // Handle error
}
```

### Logout Flow

```swift
// Clear all authentication data
await authManager.logout()
```

### Universal Links

The app automatically handles Universal Links for magic link authentication. The `onOpenURL` modifier in `finalsendApp.swift` routes magic link URLs to the AuthManager.

## Security Features

- **Keychain Storage**: Sessions are stored securely in iOS Keychain
- **Biometry Ready**: Optional Face ID/Touch ID support (can be enabled later)
- **Automatic Cleanup**: Failed sessions are automatically cleared from Keychain
- **Session Validation**: Stored sessions are validated against Supabase on restoration

## Configuration

### Universal Links

The app is configured to handle Universal Links from `finalsend.co`. To enable:

1. **Entitlements**: `com.apple.developer.associated-domains` with `applinks:finalsend.co`
2. **Domain Configuration**: Set up AASA file on `finalsend.co` (to be done later)
3. **URL Scheme**: App handles `finalsend://` URLs

### Keychain Keys

- `com.finalsend.supabase.session`: Stores the Supabase session JSON

## Testing

Run the test suite to verify functionality:

```bash
# Run auth persistence tests
xcodebuild test -scheme finalsend -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Migration Notes

### From Previous Implementation

- **@AppStorage**: Replaced with secure Keychain storage
- **SplashView**: Removed, replaced with bootstrapping in main app
- **SessionManager**: Enhanced to delegate to AuthManager while maintaining API compatibility
- **Hardcoded Clients**: All Supabase clients now use `SupabaseManager.shared.client`

### Backward Compatibility

The `SessionManager` maintains its existing API, so existing code continues to work:

```swift
// This still works
@StateObject private var sessionManager = SessionManager()
await sessionManager.loadUserProfile()
await sessionManager.logout()
```

## Future Enhancements

1. **Face ID Lock**: Add biometry requirement for app unlock
2. **Session Refresh**: Implement automatic token refresh
3. **Offline Support**: Handle offline scenarios gracefully
4. **Multi-Device Sync**: Sync sessions across user's devices

## Troubleshooting

### Common Issues

1. **Session Not Persisting**: Check Keychain permissions and entitlements
2. **Magic Links Not Working**: Verify Universal Links configuration
3. **App Crashes on Launch**: Check for Keychain access issues

### Debug Logging

The implementation includes comprehensive logging:

```
✅ Session restored from Keychain
❌ Session restoration failed: [error]
✅ Session persisted to Keychain
❌ Magic link exchange failed: [error]
```

## Dependencies

- **Supabase Swift SDK**: 2.31.2
- **iOS Deployment Target**: 16.6+
- **LocalAuthentication**: For biometry support
- **Security**: For Keychain operations


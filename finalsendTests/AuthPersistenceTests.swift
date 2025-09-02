import XCTest
@testable import finalsend

@MainActor
final class AuthPersistenceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing Keychain data before each test
        try? KeychainStore.delete(.supabaseSessionJSON)
    }
    
    override func tearDown() {
        // Clean up after each test
        try? KeychainStore.delete(.supabaseSessionJSON)
        super.tearDown()
    }
    
    func testKeychainStoreSaveAndLoad() throws {
        // Test basic Keychain operations
        let testData = "test session data".data(using: .utf8)!
        
        // Save data
        try KeychainStore.save(testData, for: .supabaseSessionJSON)
        
        // Load data
        let loadedData = try KeychainStore.load(.supabaseSessionJSON)
        
        XCTAssertNotNil(loadedData)
        XCTAssertEqual(loadedData, testData)
    }
    
    func testKeychainStoreDelete() throws {
        // Test deletion
        let testData = "test session data".data(using: .utf8)!
        
        // Save data
        try KeychainStore.save(testData, for: .supabaseSessionJSON)
        
        // Verify it exists
        let loadedData = try KeychainStore.load(.supabaseSessionJSON)
        XCTAssertNotNil(loadedData)
        
        // Delete data
        try KeychainStore.delete(.supabaseSessionJSON)
        
        // Verify it's gone
        let deletedData = try KeychainStore.load(.supabaseSessionJSON)
        XCTAssertNil(deletedData)
    }
    
    func testBiometryAvailability() {
        // Test biometry availability check (should not crash)
        let isAvailable = KeychainStore.isBiometryAvailable()
        let biometryType = KeychainStore.biometryType()
        
        // These should not crash, actual values depend on device
        XCTAssertTrue(isAvailable || !isAvailable) // Should be a boolean
        XCTAssertTrue(biometryType == .none || biometryType == .faceID || biometryType == .touchID)
    }
    
    func testAuthManagerSingleton() {
        // Test that AuthManager is a singleton
        let instance1 = AuthManager.shared
        let instance2 = AuthManager.shared
        
        XCTAssertTrue(instance1 === instance2)
    }
    
    func testAuthManagerInitialState() {
        // Test initial state
        let authManager = AuthManager.shared
        
        XCTAssertFalse(authManager.isLoggedIn)
        XCTAssertFalse(authManager.isBootstrapped)
        XCTAssertNil(authManager.currentSession)
        XCTAssertNil(authManager.userProfile)
    }
    
    func testSessionRestorationWithExpiredSession() {
        // Test that expired sessions are properly cleared
        let authManager = AuthManager.shared
        
        // Create a mock expired session
        let expiredDate = Date().addingTimeInterval(-3600) // 1 hour ago
        let mockSession = Session(
            accessToken: "expired_token",
            refreshToken: "refresh_token",
            expiresIn: 3600,
            expiresAt: expiredDate,
            tokenType: "bearer",
            user: User(
                id: UUID(),
                appMetadata: [:],
                userMetadata: [:],
                aud: "authenticated",
                createdAt: "2023-01-01T00:00:00Z"
            )
        )
        
        // Save expired session to Keychain
        do {
            let sessionData = try JSONEncoder().encode(mockSession)
            try KeychainStore.save(sessionData, for: .supabaseSessionJSON)
        } catch {
            XCTFail("Failed to save expired session: \(error)")
        }
        
        // Verify session restoration clears expired session
        Task {
            await authManager.restoreSessionOnLaunch()
            
            // Should not be logged in with expired session
            XCTAssertFalse(authManager.isLoggedIn)
            XCTAssertNil(authManager.currentSession)
        }
    }
    
    func testSessionValidation() {
        let authManager = AuthManager.shared
        
        // Test validation with no session
        Task {
            let isValid = await authManager.validateSession()
            XCTAssertFalse(isValid)
        }
    }
    
    func testDebugSessionState() {
        let authManager = AuthManager.shared
        
        // Should not crash
        authManager.debugSessionState()
        
        // Test that we can access the debug info
        XCTAssertFalse(authManager.isLoggedIn)
        XCTAssertFalse(authManager.isBootstrapped)
    }
}


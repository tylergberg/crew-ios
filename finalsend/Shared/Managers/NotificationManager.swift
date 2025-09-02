import Foundation
import UserNotifications
import SwiftUI
import Supabase

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?
    @Published var lastError: String?
    @Published var notificationPreferences: NotificationPreferences?
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let client = SupabaseManager.shared.client
    
    // MARK: - Notification Categories
    enum NotificationCategory: String, CaseIterable {
        case partyInvite = "PARTY_INVITE"
        case partyUpdate = "PARTY_UPDATE"
        case chatMessage = "CHAT_MESSAGE"
        case taskAssignment = "TASK_ASSIGNMENT"
        case expenseUpdate = "EXPENSE_UPDATE"
        case eventReminder = "EVENT_REMINDER"
        
        var displayName: String {
            switch self {
            case .partyInvite: return "Party Invites"
            case .partyUpdate: return "Party Updates"
            case .chatMessage: return "Chat Messages"
            case .taskAssignment: return "Task Assignments"
            case .expenseUpdate: return "Expense Updates"
            case .eventReminder: return "Event Reminders"
            }
        }
        
        var description: String {
            switch self {
            case .partyInvite: return "When someone invites you to a party"
            case .partyUpdate: return "When party details are updated"
            case .chatMessage: return "When someone sends a message in party chat"
            case .taskAssignment: return "When you're assigned a new task"
            case .expenseUpdate: return "When expenses are added or split"
            case .eventReminder: return "Reminders about upcoming events"
            }
        }
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        notificationCenter.delegate = self
        setupNotificationCategories()
        checkAuthorizationStatus()
        loadNotificationPreferences()
    }
    
    // MARK: - Public Methods
    
    /// Request notification permissions from the user
    func requestPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            
            await MainActor.run {
                self.isAuthorized = granted
                self.checkAuthorizationStatus()
            }
            
            if granted {
                await registerForRemoteNotifications()
            }
            
            return granted
        } catch {
            await MainActor.run {
                self.lastError = error.localizedDescription
            }
            return false
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() {
        Task {
            let settings = await notificationCenter.notificationSettings()
            await MainActor.run {
                self.authorizationStatus = settings.authorizationStatus
                self.isAuthorized = settings.authorizationStatus == .authorized
                
                // If notifications are authorized and we have a device token, re-register it
                if settings.authorizationStatus == .authorized, let token = self.deviceToken {
                    print("🔄 Re-registering device token after authorization check")
                    Task {
                        await self.registerDeviceToken(token)
                    }
                }
            }
        }
    }
    
    /// Register for remote notifications
    func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
    
    /// Handle device token registration
    func handleDeviceToken(_ deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        
        Task {
            await MainActor.run {
                self.deviceToken = tokenString
            }
            
            // Send token to Supabase
            await registerDeviceToken(tokenString)
        }
    }
    
    /// Handle device token registration failure
    func handleDeviceTokenError(_ error: Error) {
        Task {
            await MainActor.run {
                self.lastError = "Failed to register device token: \(error.localizedDescription)"
            }
        }
    }
    
    /// Send a local test notification
    func sendTestNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "This is a test notification from FinalSend!"
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "test-notification", content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                Task {
                    await MainActor.run {
                        self.lastError = "Failed to send test notification: \(error.localizedDescription)"
                    }
                }
            }
        }
    }
    
    /// Open iOS Settings for the app
    func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
    
    /// Re-register current device token
    func reRegisterDeviceToken() {
        if let token = deviceToken {
            print("🔄 Manually re-registering device token")
            Task {
                await registerDeviceToken(token)
            }
        } else {
            print("❌ No device token available to re-register")
        }
    }
    
    /// Load notification preferences from database
    func loadNotificationPreferences() {
        // Don't load preferences if user is logging out
        guard !AuthManager.shared.isLoggingOut else {
            print("⚠️ Skipping notification preferences load - user is logging out")
            return
        }
        
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        Task {
            do {
                let response: NotificationPreferences = try await client
                    .from("notification_preferences")
                    .select("*")
                    .eq("user_id", value: userId)
                    .single()
                    .execute()
                    .value
                
                print("📥 Loaded preferences from DB: partyInvites=\(response.partyInvites), partyUpdates=\(response.partyUpdates), chatMessages=\(response.chatMessages), taskAssignments=\(response.taskAssignments), expenseUpdates=\(response.expenseUpdates), eventReminders=\(response.eventReminders)")
                
                await MainActor.run {
                    self.notificationPreferences = response
                }
            } catch {
                // If no preferences exist, create default ones
                await createDefaultPreferences(userId: userId)
            }
        }
    }
    
    /// Update notification preferences
    func updateNotificationPreferences(_ preferences: NotificationPreferences) async {
        // Don't update preferences if user is logging out
        guard !AuthManager.shared.isLoggingOut else {
            print("⚠️ Skipping notification preferences update - user is logging out")
            return
        }
        
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        do {
            print("💾 NotificationManager: Saving to DB - partyInvites=\(preferences.partyInvites), partyUpdates=\(preferences.partyUpdates), chatMessages=\(preferences.chatMessages), taskAssignments=\(preferences.taskAssignments), expenseUpdates=\(preferences.expenseUpdates), eventReminders=\(preferences.eventReminders)")
            
            // Use upsert with user_id as conflict resolution key
            struct UpsertPreferencesData: Encodable {
                let user_id: String
                let party_invites: Bool
                let party_updates: Bool
                let chat_messages: Bool
                let task_assignments: Bool
                let expense_updates: Bool
                let event_reminders: Bool
            }
            
            let upsertData = UpsertPreferencesData(
                user_id: userId,
                party_invites: preferences.partyInvites,
                party_updates: preferences.partyUpdates,
                chat_messages: preferences.chatMessages,
                task_assignments: preferences.taskAssignments,
                expense_updates: preferences.expenseUpdates,
                event_reminders: preferences.eventReminders
            )
            
            let response: NotificationPreferences = try await client
                .from("notification_preferences")
                .upsert(upsertData, onConflict: "user_id")
                .single()
                .execute()
                .value
            
            print("✅ Successfully upserted preferences in DB")
            print("✅ Response from DB: partyInvites=\(response.partyInvites), partyUpdates=\(response.partyUpdates), chatMessages=\(response.chatMessages), taskAssignments=\(response.taskAssignments), expenseUpdates=\(response.expenseUpdates), eventReminders=\(response.eventReminders)")
            
            await MainActor.run {
                self.notificationPreferences = response
            }
        } catch {
            print("❌ Failed to update notification preferences: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            await MainActor.run {
                self.lastError = "Failed to update notification preferences: \(error.localizedDescription)"
            }
        }
    }
    
    /// Create default notification preferences
    private func createDefaultPreferences(userId: String) async {
        let defaultPreferences = NotificationPreferences(
            id: nil,
            userId: userId,
            partyInvites: true,
            partyUpdates: true,
            chatMessages: true,
            taskAssignments: true,
            expenseUpdates: true,
            eventReminders: true,
            createdAt: nil,
            updatedAt: nil
        )
        
        await updateNotificationPreferences(defaultPreferences)
    }
    
    // MARK: - Private Methods
    
    private func setupNotificationCategories() {
        let categories = NotificationCategory.allCases.map { category in
            UNNotificationCategory(
                identifier: category.rawValue,
                actions: [],
                intentIdentifiers: [],
                options: []
            )
        }
        
        notificationCenter.setNotificationCategories(Set(categories))
    }
    
    private func registerDeviceToken(_ token: String) async {
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        do {
            struct DeviceTokenData: Encodable {
                let user_id: String
                let device_token: String
                let platform: String
                let is_active: Bool
                let updated_at: String
            }
            
            let tokenData = DeviceTokenData(
                user_id: userId,
                device_token: token,
                platform: "ios",
                is_active: true,
                updated_at: ISO8601DateFormatter().string(from: Date())
            )
            
            try await client
                .from("device_tokens")
                .upsert(tokenData)
                .execute()
            
            print("✅ Device token registered successfully with is_active: true")
        } catch {
            print("❌ Failed to register device token: \(error)")
            await MainActor.run {
                self.lastError = "Failed to register device token with server"
            }
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
@MainActor
extension NotificationManager: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Handle notification tap
        handleNotificationTap(userInfo: userInfo)
        
        completionHandler()
    }
    
    private func handleNotificationTap(userInfo: [AnyHashable: Any]) {
        print("🔔 Notification tapped with userInfo: \(userInfo)")
        
        // Handle deep link if present
        if let deepLink = userInfo["deep_link"] as? String {
            print("🔗 Processing deep link: \(deepLink)")
            if let url = URL(string: deepLink) {
                DeepLinkRouter.handle(url: url)
                return
            }
        }
        
        // Fallback to party_id navigation
        if let partyId = userInfo["party_id"] as? String {
            print("🎉 Navigating to party: \(partyId)")
            AppNavigator.shared.navigateToParty(partyId)
        } else if let chatId = userInfo["chat_id"] as? String {
            // For now, we'll navigate to the party that contains the chat
            // In the future, we can add direct chat navigation
            print("Chat notification tapped: \(chatId)")
        }
    }
}

// MARK: - NotificationPreferences Model
struct NotificationPreferences: Codable {
    let id: String?
    let userId: String
    let partyInvites: Bool
    let partyUpdates: Bool
    let chatMessages: Bool
    let taskAssignments: Bool
    let expenseUpdates: Bool
    let eventReminders: Bool
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case partyInvites = "party_invites"
        case partyUpdates = "party_updates"
        case chatMessages = "chat_messages"
        case taskAssignments = "task_assignments"
        case expenseUpdates = "expense_updates"
        case eventReminders = "event_reminders"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

import SwiftUI
import UserNotifications

struct NotificationTestView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var authManager = AuthManager.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            List {
                Section("Session Management") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Login Status:")
                            Spacer()
                            Text(authManager.isLoggedIn ? "✅ Logged In" : "❌ Not Logged In")
                                .foregroundColor(authManager.isLoggedIn ? .green : .red)
                        }
                        
                        HStack {
                            Text("Bootstrapped:")
                            Spacer()
                            Text(authManager.isBootstrapped ? "✅ Yes" : "⏳ No")
                                .foregroundColor(authManager.isBootstrapped ? .green : .orange)
                        }
                        
                        if let email = authManager.currentUserEmail {
                            HStack {
                                Text("User Email:")
                                Spacer()
                                Text(email)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if let userId = authManager.currentUserId {
                            HStack {
                                Text("User ID:")
                                Spacer()
                                Text(userId.prefix(8) + "...")
                                    .foregroundColor(.secondary)
                                    .font(.system(.caption, design: .monospaced))
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section("Session Actions") {
                    Button("Refresh Session") {
                        Task {
                            await authManager.refreshSession()
                            alertMessage = "Session refresh completed"
                            showingAlert = true
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Validate Session") {
                        Task {
                            let isValid = await authManager.validateSession()
                            alertMessage = isValid ? "Session is valid" : "Session validation failed"
                            showingAlert = true
                        }
                    }
                    .foregroundColor(.green)
                    
                    Button("Debug Session State") {
                        authManager.debugSessionState()
                        alertMessage = "Check console for debug info"
                        showingAlert = true
                    }
                    .foregroundColor(.orange)
                    
                    Button("Force Re-authentication") {
                        Task {
                            await authManager.forceReauthentication()
                            alertMessage = "Session cleared - please log in again"
                            showingAlert = true
                        }
                    }
                    .foregroundColor(.red)
                }
                
                Section("Notification Settings") {
                    let statusText = authorizationStatusText
                    let statusColor = authorizationStatusColor
                    HStack {
                        Text("Authorization Status:")
                        Spacer()
                        Text(statusText)
                            .foregroundColor(statusColor)
                    }
                    
                    if let deviceToken = notificationManager.deviceToken {
                        HStack {
                            Text("Device Token:")
                            Spacer()
                            Text(deviceToken.prefix(20) + "...")
                                .foregroundColor(.secondary)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                    
                    Button("Request Permission") {
                        Task {
                            await notificationManager.requestPermission()
                        }
                    }
                    .foregroundColor(.blue)
                    
                    Button("Send Test Notification") {
                        notificationManager.sendTestNotification()
                    }
                    .foregroundColor(.green)
                }
                
                Section("Notification Preferences") {
                    let preferences = notificationManager.notificationPreferences
                    if let preferences = preferences {
                        ForEach(NotificationManager.NotificationCategory.allCases, id: \.self) { category in
                            let isEnabled = getPreferenceValue(for: category, from: preferences)
                            HStack {
                                Text(category.displayName)
                                Spacer()
                                Text(isEnabled ? "✅" : "❌")
                            }
                        }
                    } else {
                        Text("No preferences loaded")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("Load Preferences") {
                        Task {
                            await notificationManager.loadNotificationPreferences()
                        }
                    }
                    .foregroundColor(.blue)
                }
            }
            .navigationTitle("Debug Tools")
            .alert("Debug Info", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private var authorizationStatusText: String {
        let status = notificationManager.authorizationStatus
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        case .provisional:
            return "Provisional"
        case .ephemeral:
            return "Ephemeral"
        @unknown default:
            return "Unknown"
        }
    }
    
    private var authorizationStatusColor: Color {
        let status = notificationManager.authorizationStatus
        switch status {
        case .authorized, .provisional, .ephemeral:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        @unknown default:
            return .gray
        }
    }
    
    private func getPreferenceValue(for category: NotificationManager.NotificationCategory, from preferences: NotificationPreferences) -> Bool {
        switch category {
        case .partyInvite:
            return preferences.partyInvites
        case .partyUpdate:
            return preferences.partyUpdates
        case .chatMessage:
            return preferences.chatMessages
        case .taskAssignment:
            return preferences.taskAssignments
        case .expenseUpdate:
            return preferences.expenseUpdates
        case .eventReminder:
            return preferences.eventReminders
        }
    }
}

#Preview {
    NotificationTestView()
}

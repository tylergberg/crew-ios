import SwiftUI
import UserNotifications

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showingPermissionAlert = false
    @State private var showingTestNotification = false
    @State private var showingSaveSuccess = false
    @State private var showingSaveError = false
    @State private var isSaving = false
    @State private var showingDebugTools = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Permission Status Section
                    PermissionStatusSection()
                    
                    // Notification Categories Section
                    NotificationCategoriesSection()
                    
                    // Test Notification Section
                    TestNotificationSection()
                    
                    // Debug Tools Section (only in debug builds)
                    #if DEBUG
                    DebugToolsSection(showingDebugTools: $showingDebugTools)
                    #endif
                    
                    // Help Section
                    HelpSection()
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
            .background(Color.white)
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "#401B17")!)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        savePreferences()
                    }
                    .foregroundColor(Color(hex: "#401B17")!)
                    .disabled(isSaving)
                }
            }
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
        }
        .sheet(isPresented: $showingDebugTools) {
            NotificationTestView()
        }
        .alert("Enable Notifications", isPresented: $showingPermissionAlert) {
            Button("Settings") {
                notificationManager.openSettings()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To receive notifications, please enable them in Settings > FinalSend > Notifications")
        }
        .alert("Test Notification Sent", isPresented: $showingTestNotification) {
            Button("OK") { }
        } message: {
            Text("You should receive a test notification shortly!")
        }
        .alert("Preferences Saved", isPresented: $showingSaveSuccess) {
            Button("OK") { }
        } message: {
            Text("Your notification preferences have been saved successfully!")
        }
        .alert("Save Failed", isPresented: $showingSaveError) {
            Button("OK") { }
        } message: {
            Text("Failed to save notification preferences. Please try again.")
        }
    }
    
    private func savePreferences() {
        isSaving = true
        
        Task {
            do {
                // Get current preferences from the notification manager
                if let currentPreferences = notificationManager.notificationPreferences {
                    print("💾 Saving preferences: partyInvites=\(currentPreferences.partyInvites), partyUpdates=\(currentPreferences.partyUpdates), chatMessages=\(currentPreferences.chatMessages), taskAssignments=\(currentPreferences.taskAssignments), expenseUpdates=\(currentPreferences.expenseUpdates), eventReminders=\(currentPreferences.eventReminders)")
                    await notificationManager.updateNotificationPreferences(currentPreferences)
                    await MainActor.run {
                        showingSaveSuccess = true
                        isSaving = false
                    }
                } else {
                    // Create default preferences if none exist
                    guard let userId = AuthManager.shared.currentUserId else {
                        await MainActor.run {
                            showingSaveError = true
                            isSaving = false
                        }
                        return
                    }
                    
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
                    
                    await notificationManager.updateNotificationPreferences(defaultPreferences)
                    await MainActor.run {
                        showingSaveSuccess = true
                        isSaving = false
                    }
                }
            } catch {
                await MainActor.run {
                    showingSaveError = true
                    isSaving = false
                }
            }
        }
    }
}

// MARK: - Permission Status Section
struct PermissionStatusSection: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notification Status")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(statusText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if !notificationManager.isAuthorized {
                    Button("Enable") {
                        requestPermission()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(red: 0.93, green: 0.51, blue: 0.25))
                    .cornerRadius(8)
                }
            }
            
            if let deviceToken = notificationManager.deviceToken {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Device Token")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(deviceToken)
                        .font(.caption)
                        .foregroundColor(.primary)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(Color.white)
                .cornerRadius(8)
                
                Button("Re-register Device Token") {
                    notificationManager.reRegisterDeviceToken()
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color(red: 0.93, green: 0.51, blue: 0.25))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
    
    private var statusIcon: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "checkmark.circle.fill"
        case .denied:
            return "xmark.circle.fill"
        case .notDetermined:
            return "questionmark.circle.fill"
        case .provisional:
            return "exclamationmark.circle.fill"
        case .ephemeral:
            return "exclamationmark.circle.fill"
        @unknown default:
            return "questionmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return .green
        case .denied:
            return .red
        case .notDetermined:
            return .orange
        case .provisional, .ephemeral:
            return .blue
        @unknown default:
            return .orange
        }
    }
    
    private var statusText: String {
        switch notificationManager.authorizationStatus {
        case .authorized:
            return "Notifications are enabled"
        case .denied:
            return "Notifications are disabled. Enable in Settings."
        case .notDetermined:
            return "Notification permission not requested yet"
        case .provisional:
            return "Provisional notifications enabled"
        case .ephemeral:
            return "Ephemeral notifications enabled"
        @unknown default:
            return "Unknown notification status"
        }
    }
    
    private func requestPermission() {
        Task {
            let granted = await notificationManager.requestPermission()
            if !granted {
                // Show alert to go to settings
                await MainActor.run {
                    // This will be handled by the parent view
                }
            }
        }
    }
}

// MARK: - Notification Categories Section
struct NotificationCategoriesSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(Color(red: 0.93, green: 0.51, blue: 0.25))
                    .font(.title2)
                
                Text("Notification Types")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                ForEach(NotificationManager.NotificationCategory.allCases, id: \.self) { category in
                    NotificationCategoryRow(category: category)
                }
            }
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct NotificationCategoryRow: View {
    let category: NotificationManager.NotificationCategory
    @StateObject private var notificationManager = NotificationManager.shared
    @State private var isEnabled: Bool = true
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.displayName)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                
                Text(category.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Toggle("", isOn: $isEnabled)
                .labelsHidden()
                .onChange(of: isEnabled) { newValue in
                    updateLocalPreference(for: category, value: newValue)
                }
        }
        .padding(12)
        .background(Color(red: 0.98, green: 0.98, blue: 0.98))
        .cornerRadius(8)
        .onReceive(notificationManager.$notificationPreferences) { preferences in
            if let preferences = preferences {
                isEnabled = getValue(for: category, from: preferences)
            }
        }
    }
    
    private func getValue(for category: NotificationManager.NotificationCategory, from preferences: NotificationPreferences?) -> Bool {
        guard let preferences = preferences else { return true }
        
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
    
    private func updateLocalPreference(for category: NotificationManager.NotificationCategory, value: Bool) {
        guard let userId = AuthManager.shared.currentUserId else { return }
        
        print("🔄 Updating preference for \(category.displayName) to \(value)")
        
        // Always ensure we have preferences loaded from the database first
        if notificationManager.notificationPreferences == nil {
            print("📝 No preferences loaded, loading from database first...")
            notificationManager.loadNotificationPreferences()
            return // Exit early, the user will need to toggle again after preferences load
        }
        
        // Update the local notification preferences in the manager
        if let currentPreferences = notificationManager.notificationPreferences {
            print("📝 Current preferences: partyInvites=\(currentPreferences.partyInvites), partyUpdates=\(currentPreferences.partyUpdates), chatMessages=\(currentPreferences.chatMessages), taskAssignments=\(currentPreferences.taskAssignments), expenseUpdates=\(currentPreferences.expenseUpdates), eventReminders=\(currentPreferences.eventReminders)")
            
            // Update existing preferences - preserve all other values
            let updatedPreferences = NotificationPreferences(
                id: currentPreferences.id,
                userId: currentPreferences.userId,
                partyInvites: category == .partyInvite ? value : currentPreferences.partyInvites,
                partyUpdates: category == .partyUpdate ? value : currentPreferences.partyUpdates,
                chatMessages: category == .chatMessage ? value : currentPreferences.chatMessages,
                taskAssignments: category == .taskAssignment ? value : currentPreferences.taskAssignments,
                expenseUpdates: category == .expenseUpdate ? value : currentPreferences.expenseUpdates,
                eventReminders: category == .eventReminder ? value : currentPreferences.eventReminders,
                createdAt: currentPreferences.createdAt,
                updatedAt: currentPreferences.updatedAt
            )
            
            print("📝 Updated preferences: partyInvites=\(updatedPreferences.partyInvites), partyUpdates=\(updatedPreferences.partyUpdates), chatMessages=\(updatedPreferences.chatMessages), taskAssignments=\(updatedPreferences.taskAssignments), expenseUpdates=\(updatedPreferences.expenseUpdates), eventReminders=\(updatedPreferences.eventReminders)")
            
            // Update the local state (this won't save to database until Save is pressed)
            notificationManager.notificationPreferences = updatedPreferences
        }
    }
}

// MARK: - Test Notification Section
struct TestNotificationSection: View {
    @StateObject private var notificationManager = NotificationManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "paperplane.fill")
                    .foregroundColor(Color(red: 0.93, green: 0.51, blue: 0.25))
                    .font(.title2)
                
                Text("Test Notifications")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Button("Send Test Notification") {
                notificationManager.sendTestNotification()
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(red: 0.93, green: 0.51, blue: 0.25))
            .cornerRadius(8)
            .disabled(!notificationManager.isAuthorized)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Help Section
struct HelpSection: View {
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundColor(Color(red: 0.93, green: 0.51, blue: 0.25))
                    .font(.title2)
                
                Text("Help & Support")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text("• Notifications help you stay updated on party activities")
                Text("• You can customize which types of notifications you receive")
                Text("• Test notifications help verify your setup is working")
                Text("• If notifications aren't working, check your device settings")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
}

// MARK: - Debug Tools Section
struct DebugToolsSection: View {
    @Binding var showingDebugTools: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Debug Tools")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
            }
            
            Text("Access session debugging and troubleshooting tools")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button("Open Debug Tools") {
                showingDebugTools = true
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color.orange)
            .cornerRadius(8)
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(12)
    }
}

struct HelpRow: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Color(red: 0.93, green: 0.51, blue: 0.25))
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NotificationSettingsView()
}

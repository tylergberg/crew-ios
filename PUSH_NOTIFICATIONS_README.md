# Push Notifications Implementation

This document describes the push notification implementation for the FinalSend iOS app.

## Overview

The push notification system allows users to receive real-time updates about party activities, chat messages, task assignments, and other important events. Users can manage their notification preferences through the app's settings.

## Architecture

### Core Components

1. **NotificationManager** (`Shared/Managers/NotificationManager.swift`)
   - Centralized notification management
   - Permission handling and device token registration
   - Local and remote notification support
   - User preference management

2. **NotificationSettingsView** (`Shared/Views/NotificationSettingsView.swift`)
   - User interface for managing notification preferences
   - Permission status display
   - Test notification functionality

3. **Database Schema** (`supabase/migrations/20250120000000_add_notifications.sql`)
   - `device_tokens` table for storing user device tokens
   - `notification_preferences` table for user settings

4. **Supabase Edge Function** (`supabase/functions/send-notification/index.ts`)
   - Server-side notification delivery
   - APNs integration (placeholder)

## Features

### Notification Types

- **Party Invites** - When someone invites you to a party
- **Party Updates** - When party details are updated
- **Chat Messages** - When someone sends a message in party chat
- **Task Assignments** - When you're assigned a new task
- **Expense Updates** - When expenses are added or split
- **Event Reminders** - Reminders about upcoming events

### User Controls

- Enable/disable specific notification types
- View current permission status
- Access iOS Settings for the app
- Send test notifications
- Device token management

## Setup Instructions

### 1. Apple Developer Account

1. Enable Push Notifications capability in Xcode
2. Create APNs certificates in Apple Developer Portal
3. Configure APNs environment (development/production)

### 2. Database Setup

Run the migration to create notification tables:

```sql
-- This is handled by the migration file
-- supabase/migrations/20250120000000_add_notifications.sql
```

### 3. Supabase Configuration

1. Deploy the Edge Function:
   ```bash
   supabase functions deploy send-notification
   ```

2. Set environment variables:
   ```bash
   supabase secrets set SUPABASE_URL=your_supabase_url
   supabase secrets set SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
   ```

### 4. iOS App Configuration

The app is already configured with:
- Push Notifications capability enabled
- NotificationManager integrated into main app
- Settings UI accessible from user profile

## Usage

### For Users

1. **Access Settings**: Go to Profile → Notification Settings
2. **Grant Permission**: Tap "Enable" to request notification permissions
3. **Customize Preferences**: Toggle specific notification types on/off
4. **Test Notifications**: Use the test button to verify setup

### For Developers

#### Sending Local Notifications

```swift
// Send a test notification
NotificationManager.shared.sendTestNotification()
```

#### Sending Remote Notifications

```swift
// Call the Supabase Edge Function
let response = try await supabase.functions.invoke("send-notification", body: [
    "userId": "user-uuid",
    "payload": [
        "title": "New Party Invite",
        "body": "You've been invited to a party!",
        "category": "PARTY_INVITE",
        "data": ["party_id": "party-uuid"]
    ]
])
```

#### Managing User Preferences

```swift
// Load user preferences
await NotificationManager.shared.loadNotificationPreferences()

// Update preferences
let newPreferences = NotificationPreferences(...)
await NotificationManager.shared.updateNotificationPreferences(newPreferences)
```

## Testing

### Local Testing

1. Use `NotificationTestView` for basic functionality testing
2. Test permission requests and device token registration
3. Verify local notifications work correctly

### Remote Testing

1. Deploy the Edge Function to Supabase
2. Test with real device tokens
3. Verify notification delivery through APNs

## Security

### Row Level Security (RLS)

The database tables are protected with RLS policies:
- Users can only access their own device tokens and preferences
- All operations require authentication

### Device Token Security

- Tokens are stored securely in the database
- Tokens are associated with specific users
- Inactive tokens are automatically cleaned up

## Troubleshooting

### Common Issues

1. **Notifications Not Appearing**
   - Check permission status in iOS Settings
   - Verify device token registration
   - Check notification preferences

2. **Permission Denied**
   - Guide users to iOS Settings
   - Explain the benefits of notifications
   - Provide clear instructions

3. **Device Token Issues**
   - Check network connectivity
   - Verify Supabase configuration
   - Review error logs

### Debug Information

The NotificationManager provides debug information:
- Current authorization status
- Device token (if available)
- Error messages for failed operations

## Future Enhancements

1. **Rich Notifications**
   - Custom notification actions
   - Media attachments
   - Interactive notifications

2. **Advanced Targeting**
   - Location-based notifications
   - Time-based delivery
   - User behavior targeting

3. **Analytics**
   - Notification delivery tracking
   - User engagement metrics
   - A/B testing support

4. **Cross-Platform**
   - Android support
   - Web push notifications
   - Email fallback

## API Reference

### NotificationManager

#### Properties
- `isAuthorized: Bool` - Current permission status
- `authorizationStatus: UNAuthorizationStatus` - Detailed status
- `deviceToken: String?` - Current device token
- `notificationPreferences: NotificationPreferences?` - User preferences

#### Methods
- `requestPermission() async -> Bool` - Request notification permissions
- `checkAuthorizationStatus()` - Check current status
- `sendTestNotification()` - Send a test notification
- `openSettings()` - Open iOS Settings
- `loadNotificationPreferences()` - Load user preferences
- `updateNotificationPreferences(_:)` - Update user preferences

### NotificationPreferences

#### Properties
- `partyInvites: Bool` - Party invite notifications
- `partyUpdates: Bool` - Party update notifications
- `chatMessages: Bool` - Chat message notifications
- `taskAssignments: Bool` - Task assignment notifications
- `expenseUpdates: Bool` - Expense update notifications
- `eventReminders: Bool` - Event reminder notifications

## Dependencies

- **UserNotifications** - iOS notification framework
- **Supabase Swift SDK** - Backend integration
- **SwiftUI** - User interface

## Support

For issues or questions about the push notification implementation:
1. Check the troubleshooting section above
2. Review the debug logs in Xcode
3. Test with the NotificationTestView
4. Verify Supabase configuration

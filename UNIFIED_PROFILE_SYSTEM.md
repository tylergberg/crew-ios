# Unified Profile System

## Overview

The Unified Profile System provides a consistent profile viewing and editing experience across the entire app, whether accessed from the dashboard or within a party context.

## Architecture

### Core Components

1. **UnifiedProfileView** - Main profile view that adapts based on context
2. **EditableProfileView** - Dedicated editing interface for profile fields
3. **ProfileResponse** - Data model for profile information
4. **PartyContext** - Context wrapper for party-specific information

### Context-Aware Behavior

The system automatically adapts based on three key parameters:

- **`userId`** - The profile being viewed
- **`partyContext`** - Party-specific information (null for dashboard)
- **`isOwnProfile`** - Whether the user is viewing their own profile

## Usage Patterns

### Dashboard Context
```swift
UnifiedProfileView(
    userId: currentUserId,
    partyContext: nil,
    isOwnProfile: true
)
```

**Features:**
- Full profile display
- Edit button for own profile
- Sign out button
- No party-specific sections

### Party Context (Own Profile)
```swift
UnifiedProfileView(
    userId: attendee.userId,
    partyContext: partyContext,
    isOwnProfile: true
)
```

**Features:**
- Party-specific info at top (Role, RSVP Status)
- Full profile details below
- Edit button for profile fields
- Party-specific actions (Change RSVP, Change Role)

### Party Context (Other's Profile)
```swift
UnifiedProfileView(
    userId: attendee.userId,
    partyContext: partyContext,
    isOwnProfile: false
)
```

**Features:**
- Party-specific info at top (Role, RSVP Status)
- Full profile details below (read-only)
- Management actions for admins/organizers
- No edit button

## Profile Sections

### 1. Profile Header
- Avatar (read-only)
- Full Name
- Email (read-only)

### 2. Party-Specific Section (Party Context Only)
- **Role** - With change option for own profile
- **RSVP Status** - With change option for own profile
- **Management** - Remove from party (admins only)

### 3. Profile Details Section
- **Basic Information**
  - Phone
  - Home Address
- **Transportation**
  - Has Car (toggle)
  - Car Seat Count (conditional)
- **Preferences**
  - Beverage Preferences
  - Fun Stat
- **Social Links**
  - LinkedIn URL
  - Instagram Handle
- **Personal Information**
  - Birthday

## Editing Capabilities

### Editable Fields
- Full Name
- Phone
- Home Address
- Has Car (toggle)
- Car Seat Count
- Beverage Preferences
- Fun Stat
- LinkedIn URL
- Instagram Handle
- Birthday

### Read-Only Fields
- Email (from auth)
- Role (system-managed)
- Avatar (future enhancement)

### Party-Specific Editable Fields
- RSVP Status (own profile only)
- Role (own profile, if allowed)

## Implementation Details

### Data Flow
1. **Load Profile** - Fetch from `profiles` table
2. **Display** - Show in appropriate sections
3. **Edit** - Open `EditableProfileView` modal
4. **Save** - Update database and refresh

### Error Handling
- Network errors with user-friendly messages
- Validation errors for invalid data
- Loading states during operations

### State Management
- `UnifiedProfileViewModel` - Profile loading and display
- `EditableProfileViewModel` - Edit form state and validation
- Change tracking to enable/disable save button

## Migration from Old System

### Before
- `ProfileView` - Dashboard profile (read-only)
- `AttendeeProfileView` - Party profile (limited editing)

### After
- `UnifiedProfileView` - Single component for all contexts
- `EditableProfileView` - Dedicated editing interface
- Consistent UX across all profile interactions

## Benefits

1. **Consistency** - Same interface everywhere
2. **Maintainability** - Single codebase for profile functionality
3. **User Experience** - Familiar interaction patterns
4. **Extensibility** - Easy to add new fields or contexts
5. **Performance** - Shared components and optimized loading

## Future Enhancements

1. **Avatar Upload** - Photo picker with cropping
2. **Auto-save** - Save changes automatically
3. **Advanced Validation** - Real-time field validation
4. **Profile Completion** - Progress indicator
5. **Social Integration** - Import from social platforms
6. **Privacy Controls** - Field-level visibility settings

## Testing

### Test Cases
1. Dashboard profile viewing
2. Dashboard profile editing
3. Party profile viewing (own)
4. Party profile editing (own)
5. Party profile viewing (other)
6. Party profile management (admin)
7. Error handling
8. Loading states

### Manual Testing Checklist
- [ ] Profile loads correctly in dashboard
- [ ] Profile loads correctly in party context
- [ ] Edit button appears for own profile
- [ ] Edit button hidden for other profiles
- [ ] Party-specific fields show in party context
- [ ] Party-specific fields hidden in dashboard
- [ ] Changes save correctly
- [ ] Error messages display properly
- [ ] Loading states work correctly
- [ ] Navigation works as expected

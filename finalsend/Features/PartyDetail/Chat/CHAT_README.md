# Chat Implementation

This directory contains the complete Group Chat and AI Chat implementation for the Final Send iOS app.

## Features Implemented

### Group Chat
- ✅ Real-time messaging with Supabase Realtime
- ✅ Message pagination (load older messages)
- ✅ Auto-scroll when near bottom
- ✅ "New messages" pill when scrolled up
- ✅ Message bubbles with proper styling (green for own, cream for others)
- ✅ User avatars with fallback initials
- ✅ Connection status indicator
- ✅ Pull-to-refresh for older messages

### AI Chat
- ✅ AI assistant with quick prompts
- ✅ Thinking indicator with animated dots
- ✅ Message history persistence
- ✅ Delete chat history functionality
- ✅ Proper message styling for user vs assistant

### Shared Features
- ✅ Full-screen modal presentation
- ✅ Segmented control for switching between GC and AI
- ✅ Shared input bar with proper placeholders
- ✅ Smooth animations and transitions
- ✅ Error handling and loading states

## File Structure

```
Chat/
├── Models/
│   ├── ChatMessage.swift          # Group chat message model
│   ├── AIMessage.swift            # AI chat message model
│   └── ChatUserSummary.swift      # User info for chat
├── Services/
│   ├── PartyChatService.swift     # Group chat API and realtime
│   ├── AIChatService.swift        # AI chat API and edge function
│   └── AvatarService.swift        # User avatar loading
├── Utilities/
│   ├── ChatUnreadTracker.swift    # Unread message tracking
│   └── DateFormatters+Chat.swift  # Cached date formatters
├── Stores/
│   ├── GroupChatStore.swift       # Group chat state management
│   └── AIChatStore.swift          # AI chat state management
├── Views/
│   ├── ChatModalView.swift        # Main modal container
│   ├── GroupChatView.swift        # Group chat UI
│   └── AIChatView.swift           # AI chat UI
└── Components/
    ├── ChatMessageBubble.swift    # Message bubble component
    └── ChatAvatar.swift           # Avatar component
```

## Integration

The chat is integrated into `PartyDetailView` via the header chat button. The button now presents a full-screen modal instead of switching to a chat tab.

### Changes Made
1. Removed `.chat` case from `PartyDetailTab` enum
2. Added `showChatModal` state to `PartyDetailView`
3. Updated header chat button to present modal
4. Added sheet presentation for `ChatModalView`

## TODOs and Dependencies

### Required Implementation
1. **Current User ID**: Replace placeholder in `ChatModalView.loadCurrentUser()` with actual user ID from your session manager
2. **Attendees List**: Implement `getAttendees()` in `PartyDetailView` to fetch actual party attendees
3. **Avatar Service**: Update `AvatarService` to match your actual profiles table schema
4. **Edge Function URL**: Verify the edge function URL in `AIChatService` matches your deployment

### Database Schema Requirements
The implementation expects these Supabase tables:

```sql
-- Group chat messages
CREATE TABLE party_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id UUID REFERENCES parties(id),
    user_id UUID REFERENCES profiles(id),
    message TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE
);

-- AI chat messages
CREATE TABLE ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    party_id UUID REFERENCES parties(id),
    sender_role TEXT CHECK (sender_role IN ('user', 'assistant')),
    content TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable realtime for party_chat_messages
ALTER PUBLICATION supabase_realtime ADD TABLE party_chat_messages;
```

### Edge Function
The AI chat requires a Supabase Edge Function at `/ai-chat` that:
1. Accepts POST requests with `{ prompt, partyId }`
2. Generates AI responses
3. Persists both user and assistant messages to `ai_messages` table
4. Returns success status

## Testing

Basic unit tests are included in `PartyChatServiceTests.swift` to verify JSON decoding works correctly.

## Performance Notes

- Uses `LazyVStack` for efficient message rendering
- Cached `DateFormatter` instances
- Avatar images are cached in memory
- Scroll tracking uses preference keys for efficiency
- Realtime subscriptions are properly cleaned up

## Error Handling

- Network errors are logged but don't block UI
- Realtime connection errors show reconnect banner
- Send failures re-enable input and show feedback
- Graceful fallbacks for missing avatars and user data

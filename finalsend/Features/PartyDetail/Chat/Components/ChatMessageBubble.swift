import SwiftUI

struct ChatMessageBubble: View {
    let isOwn: Bool
    let text: String
    let timestamp: Date
    
    var body: some View {
        HStack {
            if isOwn {
                Spacer(minLength: 60)
            }
            
            Text(text)
                .foregroundColor(isOwn ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(isOwn ? Color.brandBlue : Color(.systemGray6))
                )
            
            if !isOwn {
                Spacer(minLength: 60)
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatMessageBubble(
            isOwn: false,
            text: "Hey everyone! How's the party planning going?",
            timestamp: Date()
        )
        
        ChatMessageBubble(
            isOwn: true,
            text: "Great! I'm super excited about this weekend!",
            timestamp: Date()
        )
    }
    .padding()
}

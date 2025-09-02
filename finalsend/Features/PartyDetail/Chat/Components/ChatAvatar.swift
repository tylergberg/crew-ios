import SwiftUI

struct ChatAvatar: View {
    let user: ChatUserSummary?
    let size: CGFloat
    
    @State private var avatarImage: UIImage?
    @State private var isLoading = false
    
    init(user: ChatUserSummary?, size: CGFloat = 32) {
        self.user = user
        self.size = size
    }
    
    var body: some View {
        Group {
            if let image = avatarImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                // Fallback to initials with proper ZStack layout
                ZStack {
                    Circle()
                        .fill(generateColorForName(user?.name ?? "Unknown"))
                    
                    Text(initials)
                        .font(.system(size: size * 0.4, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task {
            await loadAvatar()
        }
        .onChange(of: user?.userId) { _ in
            // Reset avatar image when user changes
            avatarImage = nil
            Task {
                await loadAvatar()
            }
        }
        .onChange(of: user?.avatarURL) { _ in
            // Reset avatar image when avatarURL changes
            avatarImage = nil
            Task {
                await loadAvatar()
            }
        }
    }
    
    private var initials: String {
        guard let user = user else { return "?" }
        let components = user.name.components(separatedBy: " ")
        if components.count >= 2 {
            return "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            return String(user.name.prefix(2)).uppercased()
        }
    }
    
    private func loadAvatar() async {
        guard let user = user,
              let avatarURL = user.avatarURL,
              !isLoading else { 
            print("🔄 ChatAvatar: Skipping load - user: \(user?.name ?? "nil"), avatarURL: \(user?.avatarURL?.absoluteString ?? "nil"), isLoading: \(isLoading)")
            return 
        }
        
        print("🔄 ChatAvatar: Loading avatar for \(user.name) from \(avatarURL.absoluteString)")
        isLoading = true
        
        do {
            let (data, _) = try await URLSession.shared.data(from: avatarURL)
            if let image = UIImage(data: data) {
                await MainActor.run {
                    self.avatarImage = image
                    print("✅ ChatAvatar: Successfully loaded avatar for \(user.name)")
                }
            } else {
                print("❌ ChatAvatar: Failed to create UIImage from data for \(user.name)")
            }
        } catch {
            print("❌ ChatAvatar: Error loading avatar for \(user.name): \(error)")
        }
        
        isLoading = false
    }
    
    private func generateColorForName(_ name: String) -> Color {
        let colors: [Color] = [
            Color(hex: "#FF6B6B") ?? .red,      // Coral Red
            Color(hex: "#4ECDC4") ?? .teal,     // Turquoise
            Color(hex: "#45B7D1") ?? .blue,     // Sky Blue
            Color(hex: "#96CEB4") ?? .green,    // Mint Green
            Color(hex: "#FFEAA7") ?? .yellow,   // Soft Yellow
            Color(hex: "#DDA0DD") ?? .purple,   // Plum
            Color(hex: "#FFB347") ?? .orange,   // Pastel Orange
            Color(hex: "#87CEEB") ?? .blue,     // Sky Blue
            Color(hex: "#98D8C8") ?? .teal,     // Sea Green
            Color(hex: "#F7DC6F") ?? .yellow    // Golden Yellow
        ]
        
        let hash = name.hashValue
        let index = abs(hash) % colors.count
        return colors[index]
    }
}

#Preview {
    VStack(spacing: 16) {
        ChatAvatar(
            user: ChatUserSummary(
                userId: UUID(),
                name: "John Doe",
                avatarURL: nil
            ),
            size: 40
        )
        
        ChatAvatar(
            user: ChatUserSummary(
                userId: UUID(),
                name: "Jane Smith",
                avatarURL: nil
            ),
            size: 32
        )
    }
    .padding()
}

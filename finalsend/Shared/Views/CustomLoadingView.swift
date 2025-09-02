import SwiftUI

// MARK: - Custom Loading View
struct CustomLoadingView: View {
    @State private var isAnimating = false
    let message: String?
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Multiple sparkles with different animations
            HStack(spacing: 8) {
                ForEach(0..<3, id: \.self) { index in
                    Image(systemName: "sparkle")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.white)
                        .rotationEffect(.degrees(isAnimating ? 360 : 0))
                        .scaleEffect(isAnimating ? 1.2 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.6)
                        .animation(
                            Animation.easeInOut(duration: 1.2)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.2),
                            value: isAnimating
                        )
                }
            }
            
            if let message = message {
                Text(message)
                    .font(.headline)
                    .foregroundColor(.white)
                    .opacity(0.9)
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    CustomLoadingView()
}

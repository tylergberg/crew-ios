import SwiftUI

struct SparkleLoadingView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.8
    
    var body: some View {
        VStack(spacing: 24) {
            // Spinning sparkle icon
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.brandBlue)
                .rotationEffect(.degrees(rotationAngle))
                .scaleEffect(scale)
                .opacity(opacity)
                .onAppear {
                    withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                        rotationAngle = 360
                    }
                    
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        scale = 1.2
                    }
                    
                    withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                        opacity = 1.0
                    }
                }
            
            // Loading text
            Text("Loading your parties...")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.metaGrey)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.neutralBackground)
    }
}

#Preview {
    SparkleLoadingView()
        .background(Color.neutralBackground)
}

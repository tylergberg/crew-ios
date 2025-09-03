import SwiftUI
import AVKit

struct VideoPlaybackView: View {
    let question: GameQuestion
    let video: GameVideo
    let onReRecord: () -> Void
    let onClose: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isLoading = true
    @State private var hasError = false
    @State private var errorMessage = ""
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Question
                questionView
                
                // Video Player
                videoPlayerView
                
                Spacer(minLength: 20)
                
                // Action Buttons
                actionButtonsView
            }
        }
        .onAppear {
            setupVideoPlayer()
        }
        .onDisappear {
            cleanupVideoPlayer()
        }
    }
    
    // MARK: - Question View
    private var questionView: some View {
        Text(question.text)
            .font(.title2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
            .padding(.top, 60)
    }
    
    // MARK: - Video Player View
    private var videoPlayerView: some View {
        VStack(spacing: 16) {
            if hasError {
                // Error State
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.largeTitle)
                        .foregroundColor(.orange)
                    
                    Text("Video Loading Error")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    Button("Retry") {
                        setupVideoPlayer()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .frame(height: 300)
            } else if isLoading {
                // Loading State
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Loading video...")
                        .font(.body)
                        .foregroundColor(.white)
                }
                .frame(height: 300)
            } else if let player = player {
                // Video Player
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .onTapGesture {
                        togglePlayback()
                    }
                
                // Playback Controls
                HStack(spacing: 20) {
                    Button(action: {
                        seekBackward()
                    }) {
                        Image(systemName: "gobackward.10")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        togglePlayback()
                    }) {
                        Image(systemName: isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                    
                    Button(action: {
                        seekForward()
                    }) {
                        Image(systemName: "goforward.10")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Re-record Button
            Button(action: onReRecord) {
                Text("Re-record")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 140)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray))
                    .cornerRadius(8)
            }
            
            // Close Button
            Button(action: onClose) {
                Text("Close")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 140)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Video Player Methods
    private func setupVideoPlayer() {
        print("🎥 Setting up video player...")
        
        // Reset state
        isLoading = true
        hasError = false
        errorMessage = ""
        
        // Validate URL
        guard let url = URL(string: video.videoUrl) else {
            print("❌ Invalid video URL: \(video.videoUrl)")
            showError("Invalid video URL")
            return
        }
        
        print("🎥 Setting up video player with URL: \(url)")
        
        // Create player with timeout handling
        player = AVPlayer(url: url)
        
        // Add periodic time observer to track playback state
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            if let player = player {
                isPlaying = player.timeControlStatus == .playing
            }
        }
        
        // Set timeout for loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isLoading {
                print("⚠️ Video loading timeout")
                self.showError("Video loading timed out. Please check your connection and try again.")
            }
        }
        
        // Start playing automatically after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if let player = self.player {
                player.play()
                self.isPlaying = true
                self.isLoading = false
            }
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            self.isLoading = false
            self.hasError = true
            self.errorMessage = message
            print("❌ Video player error: \(message)")
        }
    }
    
    private func cleanupVideoPlayer() {
        player?.pause()
        player = nil
        isLoading = false
        hasError = false
    }
    
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: newTime)
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        player.seek(to: newTime)
    }
}

#Preview {
    let sampleQuestion = GameQuestion(
        id: "template_1_1756814502894",
        text: "When did you first realize you were in love?",
        category: "relationship_romance",
        isCustom: false,
        plannerNote: "A sweet moment to capture",
        questionForRecorder: "When did you first realize you were in love?",
        questionForLiveGuest: "When did Jared first realize they were in love?"
    )
    
    let sampleVideo = GameVideo(
        questionId: "template_1_1756814502894",
        videoUrl: "https://example.com/sample-video.mp4",
        thumbnailUrl: nil,
        uploadedAt: Date(),
        duration: 30,
        respondentName: "Jaimee"
    )
    
    return VideoPlaybackView(
        question: sampleQuestion,
        video: sampleVideo,
        onReRecord: {
            print("Re-record tapped")
        },
        onClose: {
            print("Close tapped")
        }
    )
}


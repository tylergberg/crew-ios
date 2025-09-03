import SwiftUI
import AVKit

struct VideoPlaybackView: View {
    let question: GameQuestion
    let video: GameVideo
    let onReRecord: () -> Void
    let onClose: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    
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
            if let player = player {
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
            } else {
                // Loading or Error State
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                    
                    Text("Loading video...")
                        .font(.body)
                        .foregroundColor(.white)
                }
                .frame(height: 300)
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
        guard let url = URL(string: video.videoUrl) else {
            print("❌ Invalid video URL: \(video.videoUrl)")
            return
        }
        
        print("🎥 Setting up video player with URL: \(url)")
        player = AVPlayer(url: url)
        
        // Add periodic time observer to track playback state
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            if let player = player {
                isPlaying = player.timeControlStatus == .playing
            }
        }
        
        // Start playing automatically
        player?.play()
        isPlaying = true
    }
    
    private func cleanupVideoPlayer() {
        player?.pause()
        player = nil
    }
    
    private func togglePlayback() {
        if isPlaying {
            player?.pause()
        } else {
            player?.play()
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

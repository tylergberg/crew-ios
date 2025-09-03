import SwiftUI
import AVKit

struct VideoReviewView: View {
    let question: GameQuestion
    let game: PartyGame
    let videoURL: URL
    let onUse: (GameVideo) -> Void
    let onRedo: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var recordingDuration: Double = 0
    @State private var isUploading = false
    
    var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Question
                questionView
                
                // Video Player
                if isUploading {
                    uploadingView
                } else {
                    videoPlayerView
                }
                
                Spacer()
                
                // Action Buttons
                if !isUploading {
                    actionButtonsView
                }
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
    
    // MARK: - Uploading View
    private var uploadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)
            
            Text("Uploading video...")
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
            
            Text("Please wait while we save your answer")
                .font(.body)
                .foregroundColor(.white.opacity(0.8))
        }
        .frame(height: 300)
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
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 40)
    }
    
    // MARK: - Action Buttons View
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // REDO Button
            Button(action: onRedo) {
                Text("REDO")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 140)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray))
                    .cornerRadius(8)
            }
            
            // USE Button
            Button(action: {
                isUploading = true
                createAndSaveGameVideo()
            }) {
                Text("USE")
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
        player = AVPlayer(url: videoURL)
        
        // Add periodic time observer to track playback state
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            if let player = player {
                isPlaying = player.timeControlStatus == .playing
            }
        }
        
        // Get video duration
        if let duration = player?.currentItem?.duration {
            recordingDuration = CMTimeGetSeconds(duration)
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
    
    // MARK: - Video Processing
    private func createAndSaveGameVideo() {
        // Create GameVideo object
        let gameVideo = GameVideo(
            questionId: question.id,
            videoUrl: videoURL.absoluteString,
            thumbnailUrl: nil,
            uploadedAt: Date(),
            duration: Int(recordingDuration),
            respondentName: nil
        )
        
        // Call the onUse callback
        onUse(gameVideo)
        
        // Note: The uploading state will be managed by the parent view
        // which will dismiss this view when upload completes
    }
}

#Preview {
    let sampleQuestion = GameQuestion(
        id: "1",
        text: "What's Jared's biggest fear?",
        category: "relationship_romance",
        isCustom: false,
        plannerNote: nil,
        questionForRecorder: "What's Jared's biggest fear?",
        questionForLiveGuest: "What does Jared say is Jaimee's biggest fear?"
    )
    
    let sampleGame = PartyGame(
        partyId: UUID(),
        createdBy: UUID(),
        gameType: .newlywed,
        title: "Jared & Jaimee",
        recorderName: "Jaimee",
        livePlayerName: "Jared",
        questions: [sampleQuestion],
        answers: [:],
        videos: [:],
        status: .notStarted
    )
    
    // Create a dummy video URL for preview
    let dummyURL = URL(string: "https://example.com/sample-video.mp4")!
    
    return VideoReviewView(
        question: sampleQuestion,
        game: sampleGame,
        videoURL: dummyURL,
        onUse: { video in
            print("Video used: \(video)")
        },
        onRedo: {
            print("Redo recording")
        }
    )
}

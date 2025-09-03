import SwiftUI
import AVKit
import CoreMedia
import AVFoundation

struct VideoPreviewView: View {
    let question: GameQuestion
    let video: GameVideo
    let game: PartyGame
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
                
                // Close Button Only (no re-record)
                closeButtonView
            }
        }
        .onAppear {
            // Configure audio session to play even when ringer is off
            do {
                try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                try AVAudioSession.sharedInstance().setActive(true)
                print("🔊 Audio session configured for playback")
            } catch {
                print("⚠️ Failed to configure audio session: \(error)")
            }
            
            setupVideoPlayer()
        }
        .onDisappear {
            cleanupVideoPlayer()
        }
    }
    
    // MARK: - Question View
    private var questionView: some View {
        Text(question.textWithReplacedPlaceholders(using: game))
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
                // Error State (matching VideoPlaybackView)
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
                }
                .frame(height: 300)
            } else if isLoading {
                // Loading State (matching VideoPlaybackView)
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
                // Video Player (exact copy from VideoPlaybackView)
                VideoPlayer(player: player)
                    .aspectRatio(9/16, contentMode: .fit)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: 5)
                    .onTapGesture {
                        togglePlayback()
                    }
            
                // Playback Controls (exact copy from VideoPlaybackView)
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
    
    // MARK: - Close Button View
    private var closeButtonView: some View {
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
        .padding(.horizontal, 20)
        .padding(.bottom, 30)
    }
    
    // MARK: - Video Player Setup (Enhanced)
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
        
        // Create player with timeout handling (matching VideoPlaybackView)
        player = AVPlayer(url: url)
        
        // Add periodic time observer to track playback state
        player?.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { time in
            if let player = self.player {
                self.isPlaying = player.timeControlStatus == .playing
            }
        }
        
        // Observer for video end
        if let playerItem = player?.currentItem {
            NotificationCenter.default.addObserver(
                forName: .AVPlayerItemDidPlayToEndTime,
                object: playerItem,
                queue: .main
            ) { _ in
                DispatchQueue.main.async {
                    self.isPlaying = false
                    self.player?.seek(to: .zero)
                }
            }
        }
        
        // Set timeout for loading (10 seconds like VideoPlaybackView)
        DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
            if self.isLoading {
                print("⚠️ Video loading timeout")
                self.showError("Video loading timed out. Please check your connection and try again.")
            }
        }
        
        // Start playing automatically after a short delay (like VideoPlaybackView)
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
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Video Player Controls (copied from VideoPlaybackView)
    private func togglePlayback() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let seekTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        let clampedTime = CMTimeMaximum(seekTime, CMTime.zero)
        player.seek(to: clampedTime)
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let seekTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 600))
        
        if let duration = player.currentItem?.duration, duration.isValid {
            let clampedTime = CMTimeMinimum(seekTime, duration)
            player.seek(to: clampedTime)
        } else {
            player.seek(to: seekTime)
        }
    }
}

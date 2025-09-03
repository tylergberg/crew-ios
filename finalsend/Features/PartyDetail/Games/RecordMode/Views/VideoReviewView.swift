import SwiftUI
import AVKit

/// View for reviewing recorded videos with playback controls and save/retake options
struct VideoReviewView: View {
    let videoURL: URL
    let question: GameQuestion
    let game: PartyGame
    let onSave: (GameVideo) -> Void
    let onRetake: () -> Void
    
    @State private var player: AVPlayer
    
    init(videoURL: URL, question: GameQuestion, game: PartyGame, onSave: @escaping (GameVideo) -> Void, onRetake: @escaping () -> Void) {
        self.videoURL = videoURL
        self.question = question
        self.game = game
        self.onSave = onSave
        self.onRetake = onRetake
        self._player = State(initialValue: AVPlayer(url: videoURL))
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                Text("Video Review")
                    .font(.title)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.top, 20)
                
                // Question
                VStack(spacing: 8) {
                    Text("Question")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    
                    Text(question.text)
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
                .padding(.bottom, 10)
                
                // Video Player
                VideoPlayer(player: player)
                    .aspectRatio(3/4, contentMode: .fit)
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                
                Spacer()
                
                // Controls
                HStack(spacing: 50) {
                    // Retake Button
                    Button(action: {
                        player.pause()
                        onRetake()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text("Retake")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                    }
                    
                    // Play/Pause Button
                    Button(action: {
                        if player.timeControlStatus == .playing {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: player.timeControlStatus == .playing ? "pause.fill" : "play.fill")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text(player.timeControlStatus == .playing ? "Pause" : "Play")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.white)
                        .frame(width: 80)
                    }
                    
                    // Save Button
                    Button(action: {
                        player.pause()
                        saveVideo()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.medium)
                            Text("Save")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        .frame(width: 80)
                    }
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            print("🎬 VideoReviewView: onAppear - videoURL: \(videoURL)")
            player.play()
        }
        .onDisappear {
            print("🎬 VideoReviewView: onDisappear")
            player.pause()
        }
    }
    
    private func saveVideo() {
        print("🎬 VideoReviewView: saveVideo called")
        
        // Create GameVideo object
        let gameVideo = GameVideo(
            questionId: question.id,
            videoUrl: videoURL.absoluteString,
            thumbnailUrl: nil,
            uploadedAt: Date(),
            duration: nil, // Could calculate from video if needed
            respondentName: nil // Will be set by the backend
        )
        
        print("🎬 VideoReviewView: Created GameVideo: \(gameVideo)")
        onSave(gameVideo)
    }
}

#Preview {
    // This is just for preview - won't actually work
    VideoReviewView(
        videoURL: URL(string: "https://example.com/video.mp4")!,
        question: GameQuestion(
            id: "sample-id",
            text: "Sample question",
            category: "fun",
            isCustom: false,
            plannerNote: nil,
            questionForRecorder: "Sample question for recorder",
            questionForLiveGuest: "Sample question for live guest"
        ),
        game: PartyGame(
            id: UUID(),
            partyId: UUID(),
            createdBy: UUID(),
            gameType: .newlywed,
            title: "Sample Game",
            recorderName: nil,
            livePlayerName: nil,
            questions: [],
            answers: [:],
            videos: [:],
            status: .inProgress,
            createdAt: Date(),
            updatedAt: Date(),
            questionLockStatus: nil,
            questionVersion: nil,
            lockedAt: nil,
            recordingSettings: nil,
            respondentProgress: nil
        ),
        onSave: { _ in },
        onRetake: { }
    )
}

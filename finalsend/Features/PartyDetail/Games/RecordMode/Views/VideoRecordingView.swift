import SwiftUI
import AVFoundation
import AVKit

/// Video recording view that uses the shared camera manager to prevent multiple
/// camera sessions and view recreation loops.
struct VideoRecordingView: View {
    let question: GameQuestion
    let game: PartyGame
    let onVideoRecorded: (GameVideo) -> Void
    let onCancel: () -> Void
    
    // Use the shared camera manager instead of creating our own instance
    @StateObject private var cameraManager = SharedCameraManager.shared
    @State private var showingErrorAlert = false
    
    init(question: GameQuestion, game: PartyGame, onVideoRecorded: @escaping (GameVideo) -> Void, onCancel: @escaping () -> Void) {
        self.question = question
        self.game = game
        self.onVideoRecorded = onVideoRecorded
        self.onCancel = onCancel
        print("🎥 VideoRecordingView: INIT called for question: \(question.text)")
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if cameraManager.isSessionRunning, let previewLayer = cameraManager.previewLayer {
                // Show camera preview when session is running
                VStack {
                    // Camera preview
                    CameraPreviewViewNew(previewLayer: previewLayer)
                        .aspectRatio(3/4, contentMode: .fit)
                        .clipped()
                        .cornerRadius(12)
                        .padding()
                    
                    // Question display
                    VStack(spacing: 12) {
                        Text("Question")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(question.textWithReplacedPlaceholders(using: game))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                    
                    // Recording controls
                    HStack(spacing: 30) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .cornerRadius(8)
                        
                        Button(cameraManager.isRecording ? "Stop Recording" : "Start Recording") {
                            if cameraManager.isRecording {
                                cameraManager.stopRecording()
                            } else {
                                cameraManager.startRecording()
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(cameraManager.isRecording ? Color.red : Color.blue)
                        .cornerRadius(8)
                    }
                    .padding(.bottom, 30)
                }
            } else {
                // Show loading/debug view when session is not running
                VStack(spacing: 20) {
                    Text("🎥 STARTING CAMERA...")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Question: \(question.textWithReplacedPlaceholders(using: game))")
                        .font(.headline)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                    
                    if let errorMessage = cameraManager.errorMessage {
                        Text("Error: \(errorMessage)")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }
                    
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Session Running: \(cameraManager.isSessionRunning ? "Yes" : "No")")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Button("Retry Camera") {
                        startCameraSession()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                    
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.red)
                    .cornerRadius(8)
                }
                .padding()
            }
        }
        .onAppear {
            print("🎥 VideoRecordingView: onAppear called")
            print("🎥 VideoRecordingView: cameraManager: \(cameraManager)")
            print("🎥 VideoRecordingView: isSessionRunning: \(cameraManager.isSessionRunning)")
            startCameraSession()
        }
        .onDisappear {
            print("🎥 VideoRecordingView: onDisappear called")
        }
        .onChange(of: cameraManager.recordingState) { state in
            print("🎥 VideoRecordingView: Recording state changed to: \(state)")
            if case .finished(let url) = state {
                print("🎥 VideoRecordingView: Recording finished with URL: \(url)")
                
                // Create GameVideo object with local URL and pass it back immediately
                let gameVideo = GameVideo(
                    questionId: question.id,
                    videoUrl: url.absoluteString, // Keep local URL for now
                    thumbnailUrl: nil,
                    uploadedAt: Date(),
                    duration: nil,
                    respondentName: nil
                )
                
                print("🎥 VideoRecordingView: Passing video back to parent: \(gameVideo)")
                onVideoRecorded(gameVideo)
            }
        }
    }
    
    private func startCameraSession() {
        print("🎥 VideoRecordingView: Starting camera session")
        
        cameraManager.startSession { result in
            switch result {
            case .success:
                print("🎥 VideoRecordingView: ✅ Camera session started successfully")
            case .failure(let error):
                print("🎥 VideoRecordingView: ❌ Camera session failed: \(error)")
            }
        }
    }
}

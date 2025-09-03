import SwiftUI
import AVFoundation

struct RecordGameAnswersView: View {
    let game: PartyGame
    let onGameUpdated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingVideoPlayback: GameQuestion?
    @State private var showingVideoRecording = false
    @State private var selectedQuestionForRecording: GameQuestion?
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var microphonePermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header Section
                headerView
                
                // Questions List
                questionsListView
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Record Game Answers")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(settingsUrl)
                        }
                    }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            print("🎯 RecordGameAnswersView: onAppear called")
            checkPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            print("🔄 RecordGameAnswersView: App became active, re-checking permissions")
            checkPermissions()
        }
        .alert("Camera & Microphone Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("To record video answers, please grant camera and microphone access in Settings.\n\nIn Settings, scroll down to find this app and enable Camera and Microphone permissions.")
        }
                        .fullScreenCover(item: $showingVideoPlayback) { question in
                    if let video = game.videos[question.id] {
                        VideoPlaybackView(
                            question: question,
                            video: video,
                            onReRecord: {
                                if hasRequiredPermissions {
                                    showingVideoPlayback = nil
                                    selectedQuestionForRecording = question
                                    showingVideoRecording = true
                                } else {
                                    showingPermissionAlert = true
                                }
                            },
                            onClose: {
                                showingVideoPlayback = nil
                            }
                        )
                    }
                }
                .fullScreenCover(isPresented: $showingVideoRecording) {
                    if let question = selectedQuestionForRecording {
                        VideoRecordingView(
                            question: question,
                            game: game,
                            onVideoRecorded: { video in
                                // TODO: Update game.videos and refresh UI
                                showingVideoRecording = false
                                selectedQuestionForRecording = nil
                            },
                            onCancel: {
                                showingVideoRecording = false
                                selectedQuestionForRecording = nil
                            }
                        )
                    }
                }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 16) {
            // Game Title
            Text(game.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
            
            // Progress Section
            VStack(spacing: 8) {
                Text("\(recordedCount) of \(game.questions.count) questions recorded")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                // Progress Bar
                ProgressView(value: progressValue)
                    .progressViewStyle(LinearProgressViewStyle(tint: .blue))
                    .scaleEffect(x: 1, y: 2, anchor: .center)
                
                Text("\(Int(progressValue * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }
            
            // Permission Status
            if !hasRequiredPermissions {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Camera & microphone access required")
                            .font(.caption)
                            .foregroundColor(.orange)
                        HStack(spacing: 16) {
                            HStack(spacing: 4) {
                                Image(systemName: cameraPermissionStatus == .authorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(cameraPermissionStatus == .authorized ? .green : .red)
                                Text("Camera")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            HStack(spacing: 4) {
                                Image(systemName: microphonePermissionStatus == .authorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(microphonePermissionStatus == .authorized ? .green : .red)
                                Text("Microphone")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        Text("Use the gear icon in the top right to open Settings")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Camera & microphone access granted")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
        .background(Color(.systemBackground))
    }
    
    // MARK: - Questions List View
    private var questionsListView: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                // Permission Warning Banner
                if !hasRequiredPermissions {
                    VStack(spacing: 8) {
                        HStack(spacing: 12) {
                            Image(systemName: "camera.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Camera & Microphone Access Required")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Enable camera and microphone access in Settings to record video answers")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            Button("Settings") {
                                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(settingsUrl)
                                }
                            }
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .cornerRadius(8)
                        }
                    }
                    .padding(16)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                }
                
                // Add spacing after permission banner
                if !hasRequiredPermissions {
                    Spacer(minLength: 16)
                }
                
                ForEach(Array(game.questions.enumerated()), id: \.offset) { index, question in
                    QuestionStatusCard(
                        question: question,
                        questionNumber: index + 1,
                        isRecorded: isQuestionRecorded(questionId: question.id),
                        isActive: index == 0, // For now, just highlight first question
                        hasPermissions: hasRequiredPermissions,
                        onTap: {
                            if isQuestionRecorded(questionId: question.id) {
                                showingVideoPlayback = question
                            }
                        },
                        onRecord: {
                            if hasRequiredPermissions {
                                selectedQuestionForRecording = question
                                showingVideoRecording = true
                            } else {
                                showingPermissionAlert = true
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Computed Properties
    private var recordedCount: Int {
        game.videos.count
    }
    
    private var progressValue: Double {
        guard game.questions.count > 0 else { return 0 }
        return Double(recordedCount) / Double(game.questions.count)
    }
    
    private func isQuestionRecorded(questionId: String) -> Bool {
        game.videos[questionId] != nil
    }
    
    private var hasRequiredPermissions: Bool {
        cameraPermissionStatus == .authorized && microphonePermissionStatus == .authorized
    }
    
    private func checkPermissions() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        print("🔐 RecordGameAnswersView: Checking permissions - Camera: \(cameraStatus.rawValue), Microphone: \(microphoneStatus.rawValue)")
        
        cameraPermissionStatus = cameraStatus
        microphonePermissionStatus = microphoneStatus
        
        print("🔐 RecordGameAnswersView: Permissions updated - hasRequiredPermissions: \(hasRequiredPermissions)")
    }
}

// MARK: - Question Status Card
struct QuestionStatusCard: View {
    let question: GameQuestion
    let questionNumber: Int
    let isRecorded: Bool
    let isActive: Bool
    let hasPermissions: Bool
    let onTap: () -> Void
    let onRecord: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Question Number Badge
            ZStack {
                Circle()
                    .fill(badgeColor)
                    .frame(width: 32, height: 32)
                
                Text("\(questionNumber)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            // Question Content
            VStack(alignment: .leading, spacing: 4) {
                Text(question.text)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            // Status/Action Section
            HStack(spacing: 8) {
                if isRecorded {
                    // Recorded Status
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Recorded")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.green)
                    }
                } else {
                    // Record Button
                    Button(action: onRecord) {
                        HStack(spacing: 4) {
                            Image(systemName: hasPermissions ? "video.circle.fill" : "video.slash.circle.fill")
                            Text(hasPermissions ? "Record" : "No Access")
                        }
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(hasPermissions ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(hasPermissions ? Color.blue : Color(.systemGray4))
                        .cornerRadius(16)
                    }
                    .disabled(!hasPermissions)
                    .help(hasPermissions ? "Tap to record your answer" : "Camera & microphone access required")
                }
                
                // Chevron Arrow
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(backgroundColor)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(borderColor, lineWidth: isActive ? 2 : 0)
        )
        .onTapGesture {
            onTap()
        }
        .opacity(hasPermissions || isRecorded ? 1.0 : 0.6)
    }
    
    // MARK: - Computed Properties
    private var badgeColor: Color {
        isRecorded ? .green : .blue
    }
    
    private var backgroundColor: Color {
        isActive ? Color(.systemBackground) : Color(.systemGray6)
    }
    
    private var borderColor: Color {
        isActive ? .blue : .clear
    }
}

#Preview {
    // Create a sample game for preview
    let sampleGame = PartyGame(
        partyId: UUID(),
        createdBy: UUID(),
        gameType: .newlywed,
        title: "Jared & Jaimee",
        recorderName: "Jaimee",
        livePlayerName: "Jared",
        questions: [
            GameQuestion(
                id: "1",
                text: "When did you first realize you were in love?",
                category: "relationship_romance",
                isCustom: false,
                plannerNote: nil,
                questionForRecorder: "When did you first realize you were in love?",
                questionForLiveGuest: "When did Jared first realize they were in love?"
            ),
            GameQuestion(
                id: "2",
                text: "What's Jared's biggest fear?",
                category: "relationship_romance",
                isCustom: false,
                plannerNote: nil,
                questionForRecorder: "What's Jared's biggest fear?",
                questionForLiveGuest: "What does Jared say is Jaimee's biggest fear?"
            )
        ],
        answers: [:],
        videos: ["1": GameVideo(questionId: "1", videoUrl: "sample", thumbnailUrl: nil, uploadedAt: Date(), duration: nil, respondentName: nil)],
        status: .notStarted
    )
    
    return RecordGameAnswersView(
        game: sampleGame,
        onGameUpdated: {
            print("Game updated in preview")
        }
    )
}

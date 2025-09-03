import SwiftUI
import AVFoundation

struct RecordGameAnswersView: View {
    let game: PartyGame
    let onGameUpdated: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var showingVideoPlayback: GameQuestion?

    @State private var selectedQuestionForRecording: GameQuestion?
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var microphonePermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    @State private var uploadingVideo = false
    @State private var uploadError: String?
    @State private var recordedVideoURL: URL?
    @State private var recordingQuestion: GameQuestion?
    @State private var showingVideoReview = false
    @State private var localGame: PartyGame
    
    private let gamesService = PartyGamesService.shared
    
    init(game: PartyGame, onGameUpdated: @escaping () -> Void) {
        self.game = game
        self.onGameUpdated = onGameUpdated
        self._localGame = State(initialValue: game)
    }


    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerView
            
            // Upload Status
            if uploadingVideo {
                uploadingStatusView
            }
            
            // Error Status
            if let uploadError = uploadError {
                errorStatusView(uploadError)
            }
            
            // Questions List
            questionsListView
            
            Spacer()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Record Answers")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(false)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                }) {
                    Text("Settings")
                        .foregroundColor(.blue)
                }
            }
        }

        .onAppear {
            print("🎯 RecordGameAnswersView: onAppear called")
            checkPermissions()
            requestPermissionsIfNeeded()
            
            // Refresh game data to ensure we have the latest video recordings
            print("🔄 RecordGameAnswersView: Refreshing game data on page load")
            Task {
                await refreshGameData()
            }
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
            if let video = localGame.videos[question.id] {
                VideoPlaybackView(
                    question: question,
                    video: video,
                    onReRecord: {
                        if hasRequiredPermissions {
                            showingVideoPlayback = nil
                            startRecordingPreflight(for: question)
                        } else {
                            requestPermissionsIfNeeded() { granted in
                                if granted {
                                    showingVideoPlayback = nil
                                    startRecordingPreflight(for: question)
                                } else {
                                    showingPermissionAlert = true
                                }
                            }
                        }
                    },
                    onClose: {
                        showingVideoPlayback = nil
                    }
                )
            }
        }
        .background(
            NavigationLink(
                destination: selectedQuestionForRecording.map { question in
                    VideoRecordingView(
                        question: question,
                        game: localGame,
                        onVideoRecorded: { video in
                            // Store the recorded video info and show review
                            recordedVideoURL = URL(string: video.videoUrl)
                            recordingQuestion = question
                            selectedQuestionForRecording = nil
                            showingVideoReview = true
                        },
                        onCancel: {
                            selectedQuestionForRecording = nil
                        }
                    )
                    .onAppear {
                        print("🎬 Navigating to VideoRecordingView for question: \(question.text)")
                    }
                },
                isActive: Binding(
                    get: { selectedQuestionForRecording != nil },
                    set: { if !$0 { selectedQuestionForRecording = nil } }
                )
            ) {
                EmptyView()
            }
            .hidden()
        )
        .fullScreenCover(isPresented: $showingVideoReview) {
            if let videoURL = recordedVideoURL, let question = recordingQuestion {
                VideoReviewView(
                    videoURL: videoURL,
                    question: question,
                    game: localGame,
                    onSave: { video in
                        print("🎬 RecordGameAnswersView: User confirmed save, uploading video...")
                        showingVideoReview = false
                        recordedVideoURL = nil
                        recordingQuestion = nil
                        
                        Task {
                            await handleVideoRecorded(video: video, for: question)
                        }
                    },
                    onRetake: {
                        print("🎬 RecordGameAnswersView: User wants to retake")
                        showingVideoReview = false
                        recordedVideoURL = nil
                        recordingQuestion = nil
                        // Restart recording for the same question
                        startRecordingPreflight(for: question)
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
                Text("\(recordedCount) of \(localGame.questions.count) questions recorded")
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
    
    // MARK: - Upload Status Views
    private var uploadingStatusView: some View {
        HStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            
            Text("Uploading video...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
    }
    
    private func errorStatusView(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.red)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Upload failed")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.red)
                
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Dismiss") {
                uploadError = nil
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
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
                                Text("Enable camera and microphone access to record video answers")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Button("Allow Access") {
                                    requestPermissionsIfNeeded()
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .cornerRadius(8)
                                
                                Button("Settings") {
                                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                        UIApplication.shared.open(settingsUrl)
                                    }
                                }
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.gray)
                                .cornerRadius(8)
                            }
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
                
                ForEach(Array(localGame.questions.enumerated()), id: \.offset) { index, question in
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
                                startRecordingPreflight(for: question)
                            } else {
                                requestPermissionsIfNeeded() { granted in
                                    if granted {
                                        startRecordingPreflight(for: question)
                                    } else {
                                        showingPermissionAlert = true
                                    }
                                }
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
        localGame.videos.count
    }
    
    private var progressValue: Double {
        guard localGame.questions.count > 0 else { return 0 }
        return Double(recordedCount) / Double(localGame.questions.count)
    }
    
    private func isQuestionRecorded(questionId: String) -> Bool {
        localGame.videos[questionId] != nil
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
    
    private func requestPermissionsIfNeeded(completion: ((Bool) -> Void)? = nil) {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // If both already determined and not authorized, bail to alert
        if cameraStatus == .denied || micStatus == .denied || cameraStatus == .restricted || micStatus == .restricted {
            completion?(false)
            return
        }
        
        // Request camera first if needed
        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.cameraPermissionStatus = granted ? .authorized : .denied
                    if !granted {
                        completion?(false)
                        return
                    }
                    // After camera, ensure mic
                    self.requestMicrophoneIfNeeded(completion: completion)
                }
            }
            return
        }
        
        // Camera already determined, ensure mic
        requestMicrophoneIfNeeded(completion: completion)
    }
    
    private func requestMicrophoneIfNeeded(completion: ((Bool) -> Void)? = nil) {
        let micStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        if micStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.microphonePermissionStatus = granted ? .authorized : .denied
                    completion?(granted)
                }
            }
        } else {
            // Already determined
            self.microphonePermissionStatus = micStatus
            completion?(micStatus == .authorized)
        }
    }
    
    // MARK: - Preflight helpers
    private func startRecordingPreflight(for question: GameQuestion) {
        print("🚀 Starting recording for question: \(question.text)")
        print("🚀 Before setting state - selectedQuestionForRecording: \(selectedQuestionForRecording?.text ?? "nil")")
        
        // With navigation, we just need to set the question and it will navigate automatically
        // The navigationDestination(item:) will present when selectedQuestionForRecording becomes non-nil
        selectedQuestionForRecording = question
        
        print("🚀 After setting state - selectedQuestionForRecording: \(selectedQuestionForRecording?.text ?? "nil")")
    }
    
    // MARK: - Video Upload Methods
    
    @MainActor
    private func handleVideoRecorded(video: GameVideo, for question: GameQuestion) async {
        print("🎬 RecordGameAnswersView: handleVideoRecorded called for question: \(question.text)")
        uploadingVideo = true
        uploadError = nil
        
        do {
            // Get the local video URL from the video object
            guard let localVideoURL = URL(string: video.videoUrl) else {
                throw NSError(domain: "RecordGameAnswersView", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid video URL"])
            }
            
            // Use a placeholder respondent name for now - this should be the recorder's name
            let respondentName = localGame.recorderName ?? "Recorder"
            
            print("🔄 RecordGameAnswersView: Uploading video to storage...")
            let uploadedVideo = try await gamesService.uploadVideo(
                gameId: localGame.id.uuidString,
                questionId: question.id,
                videoURL: localVideoURL,
                respondentName: respondentName
            )
            
            print("✅ RecordGameAnswersView: Video uploaded successfully: \(uploadedVideo)")
            
            // Update the local game object with the new video data to trigger immediate UI refresh
            var updatedVideos = localGame.videos
            updatedVideos[question.id] = uploadedVideo
            
            // Create a new PartyGame with updated videos
            localGame = PartyGame(
                id: localGame.id,
                partyId: localGame.partyId,
                createdBy: localGame.createdBy,
                gameType: localGame.gameType,
                title: localGame.title,
                recorderName: localGame.recorderName,
                livePlayerName: localGame.livePlayerName,
                questions: localGame.questions,
                answers: localGame.answers,
                videos: updatedVideos,
                status: localGame.status,
                createdAt: localGame.createdAt,
                updatedAt: localGame.updatedAt,
                questionLockStatus: localGame.questionLockStatus,
                questionVersion: localGame.questionVersion,
                lockedAt: localGame.lockedAt,
                recordingSettings: localGame.recordingSettings,
                respondentProgress: localGame.respondentProgress
            )
            
            print("🔄 RecordGameAnswersView: Updated local game with video data")
            
            // Call the callback to refresh the parent view
            onGameUpdated()
            
            // Clear the selected question to navigate back
            selectedQuestionForRecording = nil
            
        } catch {
            print("❌ RecordGameAnswersView: Error uploading video: \(error)")
            uploadError = error.localizedDescription
        }
        
        uploadingVideo = false
    }
    
    // MARK: - Data Refresh Methods
    
    @MainActor
    private func refreshGameData() async {
        print("🔄 RecordGameAnswersView: Fetching latest game data...")
        
        do {
            // Fetch the latest game data from the server
            if let updatedGame = try await gamesService.fetchGame(id: localGame.id.uuidString) {
                print("✅ RecordGameAnswersView: Fetched updated game with \(updatedGame.videos.count) videos")
                localGame = updatedGame
            } else {
                print("⚠️ RecordGameAnswersView: No game found with id \(localGame.id.uuidString)")
            }
            
            // Also refresh the parent's games list
            onGameUpdated()
            
        } catch {
            print("❌ RecordGameAnswersView: Error refreshing game data: \(error)")
        }
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

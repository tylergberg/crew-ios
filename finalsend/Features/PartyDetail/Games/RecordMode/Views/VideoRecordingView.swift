import SwiftUI
import AVFoundation
import Photos
import Supabase

struct VideoRecordingView: View {
    let question: GameQuestion
    let game: PartyGame
    let onVideoRecorded: (GameVideo) -> Void
    let onCancel: () -> Void
    
    @State private var recordingManager: VideoRecordingManager?
    @State private var showingPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var showingVideoReview = false
    @State private var recordedVideoURL: URL?
    @State private var showingErrorAlert = false
    @State private var errorMessage = ""
    @State private var isCameraReady = false
    @State private var stateCheckTimer: Timer?

    var body: some View {
        ZStack {
            if let manager = recordingManager, isCameraReady {
                // Main recording view - only show when camera is ready
                recordingContentView(manager: manager)
            } else {
                // Loading/initialization view
                loadingView
            }
        }
        .onAppear {
            print("🎥 VideoRecordingView: onAppear called")
            // Initialize the manager only when the view appears
            if recordingManager == nil {
                print("🎥 VideoRecordingView: Creating new VideoRecordingManager")
                recordingManager = VideoRecordingManager()
                recordingManager?.checkPermissions()
            } else {
                print("🎥 VideoRecordingView: Manager already exists, previewLayer: \(recordingManager?.previewLayer != nil ? "ready" : "not ready")")
            }
            
            // Start timer to check manager state
            startStateCheckTimer()
            
            // Add a safety timeout to prevent infinite loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 10.0) {
                if !isCameraReady && recordingManager?.previewLayer == nil {
                    print("⚠️ Camera setup timeout - showing error")
                    errorMessage = "Camera setup timed out. Please try again."
                    showingErrorAlert = true
                }
            }
        }
        .onDisappear {
            stopStateCheckTimer()
        }
    }
    
    // MARK: - State Change Handlers
    private func handlePermissionStatusChange(_ status: AVAuthorizationStatus) {
        print("🎥 Permission status changed: \(status.rawValue)")
        if status == .authorized {
            print("🎥 Permissions authorized, waiting for camera setup...")
        }
    }
    
    private func handlePreviewLayerChange(_ previewLayer: AVCaptureVideoPreviewLayer?) {
        print("🎥 Preview layer updated: \(previewLayer != nil ? "ready" : "nil")")
        if previewLayer != nil {
            print("🎥 Camera is ready, updating UI")
            DispatchQueue.main.async {
                self.isCameraReady = true
            }
        }
    }
    
    private func handleRecordingStateChange(_ state: VideoRecordingManager.RecordingState) {
        print("🎥 Recording state changed: \(state)")
        switch state {
        case .error(let message):
            print("❌ Recording error: \(message)")
            DispatchQueue.main.async {
                self.errorMessage = message
                self.showingErrorAlert = true
            }
        case .finished(let url):
            print("✅ Recording finished: \(url)")
            DispatchQueue.main.async {
                self.recordedVideoURL = url
                self.showingVideoReview = true
            }
        default:
            break
        }
    }
    
    private func handleManagerChange(_ manager: VideoRecordingManager) {
        print("🎥 Manager changed, checking state...")
        
        // Check permission status
        if manager.permissionStatus == .authorized {
            print("🎥 Permissions authorized, waiting for camera setup...")
        }
        
        // Check preview layer
        if let previewLayer = manager.previewLayer {
            print("🎥 Preview layer ready, updating UI")
            DispatchQueue.main.async {
                self.isCameraReady = true
            }
        }
        
        // Check recording state
        switch manager.recordingState {
        case .error(let message):
            print("❌ Recording error: \(message)")
            DispatchQueue.main.async {
                self.errorMessage = message
                self.showingErrorAlert = true
            }
        case .finished(let url):
            print("✅ Recording finished: \(url)")
            DispatchQueue.main.async {
                self.recordedVideoURL = url
                self.showingVideoReview = true
            }
        default:
            break
        }
    }
    
    private func startStateCheckTimer() {
        print("⏰ Starting state check timer...")
        stateCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            if let manager = self.recordingManager {
                self.checkManagerState(manager)
            }
        }
    }
    
    private func stopStateCheckTimer() {
        print("⏰ Stopping state check timer...")
        stateCheckTimer?.invalidate()
        stateCheckTimer = nil
    }
    
    private func checkManagerState(_ manager: VideoRecordingManager) {
        // Check if preview layer is ready
        if !isCameraReady && manager.previewLayer != nil {
            print("🎥 Preview layer detected, updating UI")
            DispatchQueue.main.async {
                self.isCameraReady = true
            }
        }
        
        // Check for errors
        if case .error(let message) = manager.recordingState {
            print("❌ Error detected: \(message)")
            DispatchQueue.main.async {
                self.errorMessage = message
                self.showingErrorAlert = true
            }
        }
        
        // Check for finished recording
        if case .finished(let url) = manager.recordingState {
            print("✅ Recording finished: \(url)")
            DispatchQueue.main.async {
                self.recordedVideoURL = url
                self.showingVideoReview = true
            }
        }
    }
    
    // MARK: - Loading View
    private var loadingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                
                VStack(spacing: 8) {
                    Text("Initializing camera...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let manager = recordingManager {
                        Text(manager.permissionStatus == .authorized ? "Setting up camera..." : "Checking permissions...")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
                
                if let manager = recordingManager, manager.permissionStatus == .denied {
                    VStack(spacing: 12) {
                        Image(systemName: "camera.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Camera access required")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("Please enable camera and microphone access in Settings to record videos.")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Open Settings") {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .padding(.top, 10)
                    }
                }
                
                // Add retry button for other errors
                if let manager = recordingManager, manager.permissionStatus == .authorized && !isCameraReady {
                    Button("Retry Camera Setup") {
                        print("🔄 Retrying camera setup...")
                        manager.setupCamera()
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .padding(.top, 20)
                }
            }
        }
        .alert("Camera Error", isPresented: $showingErrorAlert) {
            Button("OK") {
                showingErrorAlert = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Recording Content View
    private func recordingContentView(manager: VideoRecordingManager) -> some View {
        ZStack {
            // Camera Preview
            if let previewLayer = manager.previewLayer {
                CameraPreviewView(previewLayer: previewLayer)
                    .ignoresSafeArea()
            } else {
                Color.black
                    .ignoresSafeArea()
            }
            
            VStack {
                // Top Bar
                topBar
                
                Spacer()
                
                // Question Display
                questionDisplay
                
                Spacer()
                
                // Recording Controls
                recordingControls
                
                Spacer()
            }
        }
    }
    
    // MARK: - Top Bar
    private var topBar: some View {
        HStack {
            Button("Cancel") {
                onCancel()
            }
            .foregroundColor(.white)
            .font(.body)
            
            Spacer()
            
            if recordingManager?.isRecording == true {
                // Recording indicator
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .scaleEffect(recordingManager?.isRecording == true ? 1.2 : 1.0)
                        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: recordingManager?.isRecording == true)
                    
                    Text("Recording...")
                        .font(.caption)
                        .foregroundColor(.white)
                }
            }
            
            Spacer()
            
            // Timer
            if recordingManager?.isRecording == true {
                Text(recordingManager?.formattedRecordingTime ?? "00:00")
                    .font(.caption)
                    .foregroundColor(.white)
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }
    
    // MARK: - Recording Controls
    private var recordingControls: some View {
        HStack(spacing: 40) {
            // Record/Stop Button
            Button(action: {
                guard let manager = recordingManager else { return }
                if manager.isRecording {
                    manager.stopRecording()
                } else {
                    manager.startRecording()
                }
            }) {
                ZStack {
                    Circle()
                        .fill(recordingManager?.isRecording == true ? Color.red : Color.white)
                        .frame(width: 80, height: 80)
                    
                    if recordingManager?.isRecording == true {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white)
                            .frame(width: 32, height: 32)
                    } else {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 60, height: 60)
                    }
                }
            }
        }
    }
    
    // MARK: - Question Display
    private var questionDisplay: some View {
        VStack(spacing: 16) {
            Text(question.text)
                .font(.title3)
                .fontWeight(.medium)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
        }
    }
    
    // MARK: - Permission Handling
    private func handlePermissionStatus(_ status: AVAuthorizationStatus) {
        print("🔐 Handling permission status: \(status.rawValue)")
        switch status {
        case .denied, .restricted:
            print("❌ Camera/microphone access denied or restricted")
            permissionAlertMessage = "Camera and microphone access is required to record videos. Please enable them in Settings."
            showingPermissionAlert = true
        case .notDetermined:
            print("❓ Camera/microphone permission not determined, requesting...")
            recordingManager?.requestPermissions()
        case .authorized:
            print("✅ Camera/microphone permission authorized, setting up camera...")
            recordingManager?.setupCamera()
        @unknown default:
            print("❓ Unknown permission status: \(status.rawValue)")
            break
        }
    }
    
    // MARK: - Recording State Handling
    private func handleRecordingState(_ state: VideoRecordingManager.RecordingState) {
        switch state {
        case .finished(let videoURL):
            // Show video review screen
            recordedVideoURL = videoURL
            showingVideoReview = true
        case .error(let message):
            print("❌ Recording error: \(message)")
        case .idle, .recording:
            break
        }
    }
    
    // MARK: - Video Upload and Save
    private func uploadAndSaveVideo(video: GameVideo) async {
        do {
            // Get the video URL from the GameVideo
            guard let videoURL = URL(string: video.videoUrl) else {
                print("❌ Invalid video URL: \(video.videoUrl)")
                return
            }
            
            // Create video data
            let videoData = try Data(contentsOf: videoURL)
            
            // Generate filename
            let timestamp = Int(Date().timeIntervalSince1970)
            let filename = "\(question.id)_\(timestamp).mp4"
            
            // Initialize video upload service
            let videoUploadService = VideoUploadService(supabase: SupabaseManager.shared.client)
            
            // Upload to Supabase storage
            let uploadedVideoURL = try await videoUploadService.uploadVideo(
                videoData: videoData,
                gameId: game.id.uuidString,
                questionId: question.id,
                filename: filename
            )
            
            // Create updated GameVideo object with the uploaded URL
            let updatedGameVideo = GameVideo(
                questionId: video.questionId,
                videoUrl: uploadedVideoURL,
                thumbnailUrl: video.thumbnailUrl,
                uploadedAt: video.uploadedAt,
                duration: video.duration,
                respondentName: video.respondentName
            )
            
            // Save to database
            try await videoUploadService.updateGameVideos(
                gameId: game.id.uuidString,
                newVideo: updatedGameVideo
            )
            
            // Call completion
            await MainActor.run {
                onVideoRecorded(updatedGameVideo)
            }
            
        } catch {
            print("❌ Error processing recorded video: \(error)")
            await MainActor.run {
                errorMessage = "Failed to upload video: \(error.localizedDescription)"
                showingErrorAlert = true
            }
        }
    }
}

// MARK: - Camera Preview View
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer
    
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

// MARK: - Video Recording Manager
class VideoRecordingManager: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var permissionStatus: AVAuthorizationStatus = .notDetermined
    @Published var recordingState: RecordingState = .idle
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    var recordingDuration: Double = 0
    
    private var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureMovieFileOutput?
    private var recordingTimer: Timer?
    
    enum RecordingState {
        case idle
        case recording
        case finished(URL)
        case error(String)
    }
    
    var formattedRecordingTime: String {
        let minutes = Int(recordingDuration) / 60
        let seconds = Int(recordingDuration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    func checkPermissions() {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        print("🔍 Camera permission status: \(cameraStatus.rawValue)")
        print("🔍 Microphone permission status: \(microphoneStatus.rawValue)")
        
        if cameraStatus == .authorized && microphoneStatus == .authorized {
            permissionStatus = .authorized
            print("✅ Both camera and microphone permissions granted")
            setupCamera()
        } else if cameraStatus == .denied || microphoneStatus == .denied {
            permissionStatus = .denied
            print("❌ Camera or microphone permission denied")
        } else if cameraStatus == .restricted || microphoneStatus == .restricted {
            permissionStatus = .restricted
            print("⚠️ Camera or microphone permission restricted")
        } else {
            permissionStatus = .notDetermined
            print("❓ Camera or microphone permission not determined, requesting...")
            requestPermissions()
        }
    }
    
    func requestPermissions() {
        print("🔐 Requesting camera permission...")
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            print("🔐 Camera permission granted: \(granted)")
            DispatchQueue.main.async {
                if granted {
                    print("🔐 Requesting microphone permission...")
                    AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                        print("🔐 Microphone permission granted: \(audioGranted)")
                        DispatchQueue.main.async {
                            self?.permissionStatus = audioGranted ? .authorized : .denied
                            if audioGranted {
                                print("✅ All permissions granted, setting up camera...")
                                self?.setupCamera()
                            } else {
                                print("❌ Microphone permission denied")
                            }
                        }
                    }
                } else {
                    print("❌ Camera permission denied")
                    self?.permissionStatus = .denied
                }
            }
        }
    }
    
    func setupCamera() {
        print("🎥 Setting up camera...")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let session = AVCaptureSession()
            session.sessionPreset = .high
            
            print("🎥 Created AVCaptureSession with preset: \(session.sessionPreset.rawValue)")
            
            // Start configuration
            session.beginConfiguration()
            
            print("🎥 Session configuration started")
            
            // Add video input
            guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                print("❌ No front camera available")
                DispatchQueue.main.async {
                    self?.recordingState = .error("No front camera available")
                }
                return
            }
            
            print("✅ Found front camera: \(videoDevice.localizedName)")
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                if session.canAddInput(videoInput) {
                    session.addInput(videoInput)
                } else {
                    DispatchQueue.main.async {
                        self?.recordingState = .error("Cannot add video input")
                    }
                    return
                }
            } catch {
                DispatchQueue.main.async {
                    self?.recordingState = .error("Failed to create video input: \(error.localizedDescription)")
                }
                return
            }
            
            // Add audio input
            guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
                print("❌ No audio device available")
                DispatchQueue.main.async {
                    self?.recordingState = .error("No audio device available")
                }
                return
            }
            
            print("✅ Found audio device: \(audioDevice.localizedName)")
            
            do {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    print("✅ Added audio input to session")
                } else {
                    print("❌ Cannot add audio input to session")
                    DispatchQueue.main.async {
                        self?.recordingState = .error("Cannot add audio input")
                    }
                    return
                }
            } catch {
                print("❌ Failed to create audio input: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.recordingState = .error("Failed to create audio input: \(error.localizedDescription)")
                }
                return
            }
            
            // Add video output
            let movieOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieOutput) {
                session.addOutput(movieOutput)
                self?.videoOutput = movieOutput
                print("✅ Added video output to session")
            } else {
                print("❌ Cannot add video output to session")
                DispatchQueue.main.async {
                    self?.recordingState = .error("Cannot add video output")
                }
                return
            }
            
            // Commit configuration
            session.commitConfiguration()
            print("✅ Session configuration committed")
            
            // Create preview layer
            let previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer.videoGravity = .resizeAspectFill
            
            DispatchQueue.main.async {
                print("✅ Setting up preview layer and session")
                self?.previewLayer = previewLayer
                self?.captureSession = session
                print("🎥 Preview layer set, triggering UI update")
                
                // Start running on background queue
                DispatchQueue.global(qos: .userInitiated).async {
                    print("🎥 Starting capture session...")
                    session.startRunning()
                    print("✅ Capture session started successfully")
                    
                    // Verify session is running
                    if session.isRunning {
                        print("✅ Session is confirmed running")
                    } else {
                        print("❌ Session failed to start running")
                        DispatchQueue.main.async {
                            self?.recordingState = .error("Failed to start camera session")
                        }
                        return
                    }
                    
                    // Notify main queue that setup is complete
                    DispatchQueue.main.async {
                        print("🎥 Camera setup completed successfully")
                    }
                }
            }
        }
    }
    
    func startRecording() {
        guard let videoOutput = videoOutput,
              let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            recordingState = .error("Failed to setup recording")
            return
        }
        
        let videoName = "recording_\(Date().timeIntervalSince1970).mp4"
        let videoURL = documentsPath.appendingPathComponent(videoName)
        
        videoOutput.startRecording(to: videoURL, recordingDelegate: self)
        
        isRecording = true
        recordingDuration = 0
        recordingState = .recording
        
        // Start timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }
    
    func stopRecording() {
        videoOutput?.stopRecording()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func resetForReRecording() {
        isRecording = false
        recordingDuration = 0
        recordingState = .idle
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension VideoRecordingManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            DispatchQueue.main.async {
                self.recordingState = .error("Recording failed: \(error.localizedDescription)")
            }
        } else {
            DispatchQueue.main.async {
                self.recordingState = .finished(outputFileURL)
            }
        }
    }
}

#Preview {
    let sampleQuestion = GameQuestion(
        id: "1",
        text: "When did you first realize you were in love?",
        category: "relationship_romance",
        isCustom: false,
        plannerNote: nil,
        questionForRecorder: "When did you first realize you were in love?",
        questionForLiveGuest: "When did Jared first realize they were in love?"
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
    
    return VideoRecordingView(
        question: sampleQuestion,
        game: sampleGame,
        onVideoRecorded: { video in
            print("Video recorded: \(video)")
        },
        onCancel: {
            print("Recording cancelled")
        }
    )
}

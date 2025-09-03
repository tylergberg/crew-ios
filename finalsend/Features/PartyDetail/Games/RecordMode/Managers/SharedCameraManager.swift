import Foundation
import AVFoundation
import Combine

/// Singleton camera manager that provides a single source of truth for camera operations
/// across the entire app. Prevents multiple AVCaptureSession instances and handles
/// proper lifecycle management.
@MainActor
class SharedCameraManager: NSObject, ObservableObject {
    
    // MARK: - Singleton
    static let shared = SharedCameraManager()
    
    // MARK: - Published Properties
    @Published var isRecording = false
    @Published var isSessionRunning = false
    @Published var isSessionReady = false
    @Published var previewLayer: AVCaptureVideoPreviewLayer?
    @Published var errorMessage: String?
    @Published var recordingState: RecordingState = .idle
    @Published var recordingDuration: TimeInterval = 0
    
    // MARK: - Private Properties
    private var captureSession: AVCaptureSession?
    private var videoInput: AVCaptureDeviceInput?
    private var audioInput: AVCaptureDeviceInput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var recordingTimer: Timer?
    
    // MARK: - Session Management
    private let sessionQueue = DispatchQueue(label: "camera.session.queue", qos: .userInitiated)
    private var isConfiguringSession = false
    private var sessionConfigurationTask: Task<Void, Never>?
    
    // MARK: - Enums
    enum RecordingState: Equatable {
        case idle
        case recording
        case finished(URL)
        case error(String)
    }
    
    enum CameraError: LocalizedError {
        case permissionDenied
        case noCameraAvailable
        case noMicrophoneAvailable
        case sessionConfigurationFailed
        case sessionFailed
        case recordingFailed(String)
        case sessionAlreadyRunning
        case sessionNotReady
        
        var errorDescription: String? {
            switch self {
            case .permissionDenied:
                return "Camera and microphone access is required to record videos."
            case .noCameraAvailable:
                return "No camera is available on this device."
            case .noMicrophoneAvailable:
                return "No microphone is available on this device."
            case .sessionConfigurationFailed:
                return "Failed to configure camera session."
            case .sessionFailed:
                return "Failed to start camera session."
            case .recordingFailed(let message):
                return "Recording failed: \(message)"
            case .sessionAlreadyRunning:
                return "Camera session is already running."
            case .sessionNotReady:
                return "Camera session is not ready."
            }
        }
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
        print("🎥 SharedCameraManager: Singleton initialized")
        
        // Add session interruption notifications
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionWasInterrupted),
            name: .AVCaptureSessionWasInterrupted,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(sessionInterruptionEnded),
            name: .AVCaptureSessionInterruptionEnded,
            object: nil
        )
    }
    
    deinit {
        print("🎥 SharedCameraManager: Deinitializing")
        NotificationCenter.default.removeObserver(self)
        
        // Don't call cleanup() from deinit due to main actor isolation
        // Just clean up what we can safely
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    // MARK: - Public Interface
    
    /// Starts the camera session. This is the main entry point for camera operations.
    /// - Parameter completion: Called when the session is ready or fails
    func startSession(completion: @escaping (Result<Void, CameraError>) -> Void) {
        print("🎥 SharedCameraManager: startSession called")
        
        // Prevent multiple simultaneous start attempts
        guard !isConfiguringSession else {
            print("🎥 SharedCameraManager: ⚠️ Session configuration already in progress")
            completion(.failure(.sessionAlreadyRunning))
            return
        }
        
        // Check if session is already running
        if isSessionRunning {
            print("🎥 SharedCameraManager: ✅ Session already running")
            completion(.success(()))
            return
        }
        
        // Check permissions first
        guard checkPermissions() else {
            print("🎥 SharedCameraManager: ❌ Permissions not granted")
            completion(.failure(.permissionDenied))
            return
        }
        
        // Start session configuration
        configureAndStartSession(completion: completion)
    }
    
    /// Stops the camera session
    func stopSession() {
        print("🎥 SharedCameraManager: stopSession called")
        
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            if let session = self.captureSession, session.isRunning {
                session.stopRunning()
                print("🎥 SharedCameraManager: ✅ Session stopped")
            }
            
            Task { @MainActor in
                self.isSessionRunning = false
                self.isSessionReady = false
            }
        }
    }
    
    /// Starts recording video
    func startRecording() -> Result<Void, CameraError> {
        print("🎥 SharedCameraManager: startRecording called")
        
        guard isSessionReady else {
            print("🎥 SharedCameraManager: ❌ Session not ready for recording")
            return .failure(.sessionNotReady)
        }
        
        guard let movieOutput = movieOutput, !isRecording else {
            print("🎥 SharedCameraManager: ❌ Cannot start recording - already recording or no output")
            return .failure(.recordingFailed("Recording already in progress"))
        }
        
        // Create output file URL
        let outputURL = createOutputURL()
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        
        isRecording = true
        recordingDuration = 0
        recordingState = .recording
        
        // Start timer
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.recordingDuration += 0.1
            }
        }
        
        print("🎥 SharedCameraManager: ✅ Recording started")
        return .success(())
    }
    
    /// Stops recording video
    func stopRecording() {
        print("🎥 SharedCameraManager: stopRecording called")
        
        guard isRecording, let movieOutput = movieOutput else {
            print("🎥 SharedCameraManager: ⚠️ Not recording or no output available")
            return
        }
        
        movieOutput.stopRecording()
        isRecording = false
        
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        print("🎥 SharedCameraManager: ✅ Recording stopped")
    }
    
    /// Cleans up the camera session and resources
    func cleanup() {
        print("🎥 SharedCameraManager: 🧹 Cleanup called")
        
        // Cancel any ongoing configuration
        sessionConfigurationTask?.cancel()
        sessionConfigurationTask = nil
        
        // Stop recording if active
        if isRecording {
            stopRecording()
        }
        
        // Stop session
        stopSession()
        
        // Clear preview layer
        previewLayer = nil
        
        // Clear references
        videoInput = nil
        audioInput = nil
        movieOutput = nil
        captureSession = nil
        
        print("🎥 SharedCameraManager: ✅ Cleanup complete")
    }
    
    /// Clears any error messages
    func clearError() {
        errorMessage = nil
        if case .error = recordingState {
            recordingState = .idle
        }
    }
    
    // MARK: - Private Methods
    
    private func checkPermissions() -> Bool {
        let cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let microphoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        print("🎥 SharedCameraManager: Permission check - Camera: \(cameraStatus.rawValue), Microphone: \(microphoneStatus.rawValue)")
        
        return cameraStatus == .authorized && microphoneStatus == .authorized
    }
    
    private func configureAndStartSession(completion: @escaping (Result<Void, CameraError>) -> Void) {
        print("🎥 SharedCameraManager: 🔧 Starting session configuration")
        
        isConfiguringSession = true
        
        // Cancel any existing configuration task
        sessionConfigurationTask?.cancel()
        
        // Create new configuration task
        sessionConfigurationTask = Task { [weak self] in
            guard let self = self else { return }
            
            do {
                try await self.configureSession()
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                // Start session on background thread
                try await self.startSessionOnBackgroundThread()
                
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                // Update UI on main actor
                await MainActor.run {
                    self.isSessionRunning = true
                    self.isSessionReady = true
                    self.isConfiguringSession = false
                    print("🎥 SharedCameraManager: ✅ Session started successfully")
                    completion(.success(()))
                }
                
            } catch {
                // Check if task was cancelled
                if Task.isCancelled { return }
                
                await MainActor.run {
                    self.isConfiguringSession = false
                    self.errorMessage = error.localizedDescription
                    self.recordingState = .error(error.localizedDescription)
                    print("🎥 SharedCameraManager: ❌ Session configuration failed: \(error)")
                    completion(.failure(.sessionConfigurationFailed))
                }
            }
        }
    }
    
    private func configureSession() async throws {
        print("🎥 SharedCameraManager: 🔧 Configuring capture session")
        
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: CameraError.sessionConfigurationFailed)
                    return
                }
                
                do {
                    // Create new session
                    let session = AVCaptureSession()
                    session.sessionPreset = .high
                    
                    // Setup video input
                    guard self.setupVideoInput(for: session) else {
                        continuation.resume(throwing: CameraError.noCameraAvailable)
                        return
                    }
                    
                    // Setup audio input
                    guard self.setupAudioInput(for: session) else {
                        continuation.resume(throwing: CameraError.noMicrophoneAvailable)
                        return
                    }
                    
                    // Setup movie output
                    guard self.setupMovieOutput(for: session) else {
                        continuation.resume(throwing: CameraError.sessionConfigurationFailed)
                        return
                    }
                    
                    // Store session
                    self.captureSession = session
                    
                    // Create preview layer
                    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
                    previewLayer.videoGravity = .resizeAspectFill
                    previewLayer.connection?.videoOrientation = .portrait
                    
                    // Update UI on main actor
                    Task { @MainActor in
                        self.previewLayer = previewLayer
                    }
                    
                    print("🎥 SharedCameraManager: ✅ Session configured successfully")
                    continuation.resume()
                    
                } catch {
                    print("🎥 SharedCameraManager: ❌ Session configuration error: \(error)")
                    continuation.resume(throwing: CameraError.sessionConfigurationFailed)
                }
            }
        }
    }
    
    private func startSessionOnBackgroundThread() async throws {
        print("🎥 SharedCameraManager: 🚀 Starting session on background thread")
        
        return try await withCheckedThrowingContinuation { continuation in
            sessionQueue.async { [weak self] in
                guard let self = self, let session = self.captureSession else {
                    continuation.resume(throwing: CameraError.sessionConfigurationFailed)
                    return
                }
                
                // Configure audio session
                do {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(.playAndRecord, mode: .videoRecording, options: [.defaultToSpeaker, .allowBluetooth])
                    try audioSession.setActive(true)
                    print("🎥 SharedCameraManager: ✅ Audio session configured")
                } catch {
                    print("🎥 SharedCameraManager: ⚠️ Audio session configuration failed: \(error)")
                    // Continue anyway - audio might still work
                }
                
                // Start session
                session.startRunning()
                
                // Wait a moment for session to start
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if session.isRunning {
                        print("🎥 SharedCameraManager: ✅ Session started on background thread")
                        continuation.resume()
                    } else {
                        print("🎥 SharedCameraManager: ❌ Session failed to start")
                        continuation.resume(throwing: CameraError.sessionFailed)
                    }
                }
            }
        }
    }
    
    private func setupVideoInput(for session: AVCaptureSession) -> Bool {
        print("🎥 SharedCameraManager: 📹 Setting up video input")
        
        // Get front camera
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("🎥 SharedCameraManager: ❌ No front camera available")
            return false
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if session.canAddInput(videoInput) {
                session.addInput(videoInput)
                self.videoInput = videoInput
                print("🎥 SharedCameraManager: ✅ Video input added")
                return true
            } else {
                print("🎥 SharedCameraManager: ❌ Cannot add video input")
                return false
            }
        } catch {
            print("🎥 SharedCameraManager: ❌ Video input setup failed: \(error)")
            return false
        }
    }
    
    private func setupAudioInput(for session: AVCaptureSession) -> Bool {
        print("🎥 SharedCameraManager: 🎤 Setting up audio input")
        
        guard let audioDevice = AVCaptureDevice.default(for: .audio) else {
            print("🎥 SharedCameraManager: ❌ No audio device available")
            return false
        }
        
        do {
            let audioInput = try AVCaptureDeviceInput(device: audioDevice)
            
            if session.canAddInput(audioInput) {
                session.addInput(audioInput)
                self.audioInput = audioInput
                print("🎥 SharedCameraManager: ✅ Audio input added")
                return true
            } else {
                print("🎥 SharedCameraManager: ❌ Cannot add audio input")
                return false
            }
        } catch {
            print("🎥 SharedCameraManager: ❌ Audio input setup failed: \(error)")
            return false
        }
    }
    
    private func setupMovieOutput(for session: AVCaptureSession) -> Bool {
        print("🎥 SharedCameraManager: 🎬 Setting up movie output")
        
        let movieOutput = AVCaptureMovieFileOutput()
        
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            
            // Set video orientation
            if let connection = movieOutput.connection(with: .video) {
                if connection.isVideoOrientationSupported {
                    connection.videoOrientation = .portrait
                }
                
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            
            self.movieOutput = movieOutput
            print("🎥 SharedCameraManager: ✅ Movie output added")
            return true
        } else {
            print("🎥 SharedCameraManager: ❌ Cannot add movie output")
            return false
        }
    }
    
    private func createOutputURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileName = "recording_\(Date().timeIntervalSince1970).mp4"
        return documentsPath.appendingPathComponent(fileName)
    }
    
    // MARK: - Session Interruption Handling
    
    @objc private func sessionWasInterrupted(notification: Notification) {
        print("🎥 SharedCameraManager: 🚨 SESSION WAS INTERRUPTED!")
        
        if let userInfo = notification.userInfo,
           let reasonValue = userInfo[AVCaptureSessionInterruptionReasonKey] as? Int,
           let reason = AVCaptureSession.InterruptionReason(rawValue: reasonValue) {
            
            print("🎥 SharedCameraManager: Interruption reason: \(reason)")
            
            switch reason {
            case .videoDeviceNotAvailableInBackground:
                print("🎥 SharedCameraManager: Video device not available in background")
            case .videoDeviceInUseByAnotherClient:
                print("🎥 SharedCameraManager: Video device in use by another client")
            case .audioDeviceInUseByAnotherClient:
                print("🎥 SharedCameraManager: Audio device in use by another client")
            case .videoDeviceNotAvailableWithMultipleForegroundApps:
                print("🎥 SharedCameraManager: Video device not available with multiple foreground apps")
            case .videoDeviceNotAvailableDueToSystemPressure:
                print("🎥 SharedCameraManager: Video device not available due to system pressure")
            @unknown default:
                print("🎥 SharedCameraManager: Unknown interruption reason: \(reasonValue)")
            }
        }
        
        // Update UI state
        isSessionRunning = false
        isSessionReady = false
        errorMessage = "Camera session was interrupted"
        recordingState = .error("Camera session was interrupted")
    }
    
    @objc private func sessionInterruptionEnded(notification: Notification) {
        print("🎥 SharedCameraManager: ✅ SESSION INTERRUPTION ENDED!")
        
        // Clear error and attempt to restart
        clearError()
        
        // Wait a moment for system to stabilize, then restart
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.restartSessionAfterInterruption()
        }
    }
    
    private func restartSessionAfterInterruption() {
        print("🎥 SharedCameraManager: 🔄 Restarting session after interruption")
        
        startSession { result in
            switch result {
            case .success:
                print("🎥 SharedCameraManager: ✅ Session restarted successfully after interruption")
            case .failure(let error):
                print("🎥 SharedCameraManager: ❌ Failed to restart session after interruption: \(error)")
            }
        }
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate
extension SharedCameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            if let error = error {
                self.recordingState = .error(error.localizedDescription)
                print("🎥 SharedCameraManager: ❌ Recording failed: \(error)")
            } else {
                self.recordingState = .finished(outputFileURL)
                print("🎥 SharedCameraManager: ✅ Recording finished: \(outputFileURL)")
            }
        }
    }
}

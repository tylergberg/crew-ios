import Foundation
import AVFoundation
import Combine
import UIKit

/// Manages camera and microphone permissions without causing view recreation loops.
/// Provides a clean interface for checking and requesting permissions.
@MainActor
class PermissionCoordinator: ObservableObject {
    
    // MARK: - Published Properties
    @Published var cameraStatus: AVAuthorizationStatus = .notDetermined
    @Published var microphoneStatus: AVAuthorizationStatus = .notDetermined
    
    // MARK: - Computed Properties
    var hasRequiredPermissions: Bool {
        cameraStatus == .authorized && microphoneStatus == .authorized
    }
    
    var isPermissionDetermined: Bool {
        cameraStatus != .notDetermined && microphoneStatus != .notDetermined
    }
    
    var permissionStatusDescription: String {
        if hasRequiredPermissions {
            return "Camera and microphone access granted"
        } else if cameraStatus == .denied || microphoneStatus == .denied {
            return "Camera and microphone access required"
        } else if cameraStatus == .restricted || microphoneStatus == .restricted {
            return "Camera and microphone access is restricted"
        } else {
            return "Requesting camera and microphone access..."
        }
    }
    
    // MARK: - Initialization
    init() {
        print("🔐 PermissionCoordinator: Initialized")
        
        // Check current permissions on init
        checkCurrentPermissions()
        
        // Listen for app becoming active to re-check permissions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    deinit {
        print("🔐 PermissionCoordinator: Deinitializing")
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Interface
    
    /// Checks current permission status without triggering permission requests
    func checkCurrentPermissions() {
        print("🔐 PermissionCoordinator: Checking current permissions")
        
        let newCameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        let newMicrophoneStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // Only update if status actually changed to prevent unnecessary view updates
        if newCameraStatus != cameraStatus {
            print("🔐 PermissionCoordinator: Camera status changed: \(cameraStatus.rawValue) → \(newCameraStatus.rawValue)")
            cameraStatus = newCameraStatus
        }
        
        if newMicrophoneStatus != microphoneStatus {
            print("🔐 PermissionCoordinator: Microphone status changed: \(microphoneStatus.rawValue) → \(newMicrophoneStatus.rawValue)")
            microphoneStatus = newMicrophoneStatus
        }
        
        print("🔐 PermissionCoordinator: Current status - Camera: \(cameraStatus.rawValue), Microphone: \(microphoneStatus.rawValue), HasRequired: \(hasRequiredPermissions)")
    }
    
    /// Requests permissions if they haven't been determined yet
    /// - Parameter completion: Called with the result of permission requests
    func requestPermissionsIfNeeded(completion: @escaping (Bool) -> Void) {
        print("🔐 PermissionCoordinator: Requesting permissions if needed")
        
        // If permissions are already determined and not authorized, bail out
        if (cameraStatus == .denied || cameraStatus == .restricted) ||
           (microphoneStatus == .denied || microphoneStatus == .restricted) {
            print("🔐 PermissionCoordinator: Permissions already denied/restricted")
            completion(false)
            return
        }
        
        // If both permissions are already authorized, we're good
        if hasRequiredPermissions {
            print("🔐 PermissionCoordinator: Permissions already granted")
            completion(true)
            return
        }
        
        // Request permissions sequentially
        requestPermissionsSequentially(completion: completion)
    }
    
    /// Opens the app's settings page
    func openSettings() {
        guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
            print("🔐 PermissionCoordinator: ❌ Cannot create settings URL")
            return
        }
        
        print("🔐 PermissionCoordinator: Opening settings")
        UIApplication.shared.open(settingsUrl)
    }
    
    // MARK: - Private Methods
    
    private func requestPermissionsSequentially(completion: @escaping (Bool) -> Void) {
        print("🔐 PermissionCoordinator: Starting sequential permission requests")
        
        // Request camera permission first
        if cameraStatus == .notDetermined {
            print("🔐 PermissionCoordinator: Requesting camera permission")
            
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    guard let self = self else { return }
                    
                    print("🔐 PermissionCoordinator: Camera permission result: \(granted)")
                    self.cameraStatus = granted ? .authorized : .denied
                    
                    if granted {
                        // Camera granted, now request microphone
                        self.requestMicrophonePermission(completion: completion)
                    } else {
                        // Camera denied, we're done
                        print("🔐 PermissionCoordinator: Camera permission denied, stopping")
                        completion(false)
                    }
                }
            }
        } else if microphoneStatus == .notDetermined {
            // Camera already determined, just request microphone
            requestMicrophonePermission(completion: completion)
        } else {
            // Both permissions already determined
            print("🔐 PermissionCoordinator: Both permissions already determined")
            completion(hasRequiredPermissions)
        }
    }
    
    private func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        print("🔐 PermissionCoordinator: Requesting microphone permission")
        
        AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
            Task { @MainActor in
                guard let self = self else { return }
                
                print("🔐 PermissionCoordinator: Microphone permission result: \(granted)")
                self.microphoneStatus = granted ? .authorized : .denied
                
                let finalResult = self.hasRequiredPermissions
                print("🔐 PermissionCoordinator: Final permission result: \(finalResult)")
                completion(finalResult)
            }
        }
    }
    
    // MARK: - Notification Handling
    
    @objc private func appDidBecomeActive() {
        print("🔐 PermissionCoordinator: App became active, re-checking permissions")
        
        // Re-check permissions when app becomes active
        // This handles the case where user goes to Settings and comes back
        checkCurrentPermissions()
    }
}

// MARK: - Permission Status Extensions

extension AVAuthorizationStatus {
    var displayName: String {
        switch self {
        case .notDetermined:
            return "Not Determined"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
    
    var shortDisplayName: String {
        switch self {
        case .notDetermined:
            return "Pending"
        case .restricted:
            return "Restricted"
        case .denied:
            return "Denied"
        case .authorized:
            return "Granted"
        @unknown default:
            return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .notDetermined:
            return "questionmark.circle"
        case .restricted:
            return "exclamationmark.triangle"
        case .denied:
            return "xmark.circle"
        case .authorized:
            return "checkmark.circle"
        @unknown default:
            return "questionmark.circle"
        }
    }
    
    var iconColor: String {
        switch self {
        case .notDetermined:
            return "orange"
        case .restricted:
            return "orange"
        case .denied:
            return "red"
        case .authorized:
            return "green"
        @unknown default:
            return "gray"
        }
    }
}

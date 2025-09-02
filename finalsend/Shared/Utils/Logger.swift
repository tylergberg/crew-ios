import Foundation
import os.log

/// Centralized logging utility for the app
/// Controls debug output and provides consistent logging levels
class AppLogger {
    static let shared = AppLogger()
    
    // MARK: - Logging Configuration
    private let isDebugMode: Bool
    
    private init() {
        #if DEBUG
        self.isDebugMode = true
        #else
        self.isDebugMode = false
        #endif
    }
    
    // MARK: - Logging Methods
    
    /// Log debug information (only in debug builds)
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isDebugMode else { return }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("🔍 [\(fileName):\(line)] \(message)")
    }
    
    /// Log info messages (always shown)
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("ℹ️ [\(fileName):\(line)] \(message)")
    }
    
    /// Log success messages (always shown)
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("✅ [\(fileName):\(line)] \(message)")
    }
    
    /// Log warning messages (always shown)
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("⚠️ [\(fileName):\(line)] \(message)")
    }
    
    /// Log error messages (always shown)
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("❌ [\(fileName):\(line)] \(message)")
    }
    
    /// Log auth-related messages (always shown)
    func auth(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("🔐 [\(fileName):\(line)] \(message)")
    }
    
    /// Log data loading messages (always shown)
    func data(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("📊 [\(fileName):\(line)] \(message)")
    }
    
    /// Log network-related messages (always shown)
    func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("🌐 [\(fileName):\(line)] \(message)")
    }
    
    /// Log UI-related messages (debug only)
    func ui(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard isDebugMode else { return }
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        print("🎨 [\(fileName):\(line)] \(message)")
    }
}

// MARK: - Convenience Extensions

extension AppLogger {
    /// Quick access to shared logger
    static func debug(_ message: String) {
        shared.debug(message)
    }
    
    static func info(_ message: String) {
        shared.info(message)
    }
    
    static func success(_ message: String) {
        shared.success(message)
    }
    
    static func warning(_ message: String) {
        shared.warning(message)
    }
    
    static func error(_ message: String) {
        shared.error(message)
    }
    
    static func auth(_ message: String) {
        shared.auth(message)
    }
    
    static func data(_ message: String) {
        shared.data(message)
    }
    
    static func network(_ message: String) {
        shared.network(message)
    }
    
    static func ui(_ message: String) {
        shared.ui(message)
    }
}

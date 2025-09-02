import Foundation
import SwiftUI

enum AppRoute {
    case dashboard
    case party(id: String, openChat: Bool = false)
    case login
    case signup
    case phoneAuth
    case gameRecording(token: String)
    
    var isNeutral: Bool {
        switch self {
        case .dashboard, .party:
            return false
        case .login, .signup, .phoneAuth, .gameRecording:
            return true
        }
    }
}

@MainActor
class AppNavigator: ObservableObject {
    static let shared = AppNavigator()
    
    @Published var route: AppRoute = .dashboard
    @Published var showErrorAlert = false
    @Published var errorMessage = ""
    @Published var showSuccessAlert = false
    @Published var successTitle = ""
    @Published var successMessage = ""
    
    private init() {}
    
    func navigateToParty(_ partyId: String, openChat: Bool = false) {
        route = .party(id: partyId, openChat: openChat)
    }
    
    func navigateToDashboard() {
        route = .dashboard
    }
    
    func navigateToLogin() {
        route = .login
    }
    
    func navigateToSignup() {
        route = .signup
    }
    
    func navigateToPhoneAuth() {
        route = .phoneAuth
    }
    

    
    func navigateToGameRecording(token: String) {
        print("🎮 AppNavigator: Setting route to gameRecording with token: \(token)")
        route = .gameRecording(token: token)
        print("🎮 AppNavigator: Route is now: \(route)")
    }
    
    func showError(message: String) {
        errorMessage = message
        showErrorAlert = true
    }
    
    func showSuccessAlert(title: String, message: String) {
        successTitle = title
        successMessage = message
        showSuccessAlert = true
    }
}

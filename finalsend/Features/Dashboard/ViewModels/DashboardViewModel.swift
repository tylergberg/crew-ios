import Foundation
import SwiftUI

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var unreadTaskCount = 0
    @Published var isLoadingTaskCount = false
    
    private let notificationCenterService = NotificationCenterService()
    
    func loadUnreadTaskCount() async {
        isLoadingTaskCount = true
        
        do {
            unreadTaskCount = try await notificationCenterService.getUnreadTaskCount()
        } catch {
            print("Failed to load unread task count: \(error)")
            unreadTaskCount = 0
        }
        
        isLoadingTaskCount = false
    }
    
    func refreshTaskCount() async {
        await loadUnreadTaskCount()
    }
}



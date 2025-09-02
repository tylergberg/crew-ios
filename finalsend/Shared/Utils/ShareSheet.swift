import SwiftUI
import UIKit

// MARK: - ShareSheet Wrapper
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    let excludedActivityTypes: [UIActivity.ActivityType]?
    
    init(activityItems: [Any], excludedActivityTypes: [UIActivity.ActivityType]? = nil) {
        self.activityItems = activityItems
        self.excludedActivityTypes = excludedActivityTypes
    }
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        // Apply excluded activity types if provided
        if let excludedTypes = excludedActivityTypes {
            controller.excludedActivityTypes = excludedTypes
        }
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No updates needed
    }
}

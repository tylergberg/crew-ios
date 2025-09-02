import SwiftUI

struct FeedbackCard: View {
    var onOpenFeedback: (() -> Void)?

    var body: some View {
        OverviewCard(iconName: "bubble.left.and.bubble.right", title: "Feedback") {
            HStack {
                Text("Share your ideas to improve this party experience.")
                    .font(.subheadline)
                    .foregroundColor(.black)
                Spacer()
                Button("Give Feedback") {
                    onOpenFeedback?()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }
}



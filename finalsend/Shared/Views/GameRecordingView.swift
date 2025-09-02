import SwiftUI

struct GameRecordingView: View {
    var inviteToken: String? = nil

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "gamecontroller")
                .font(.system(size: 48))
                .foregroundColor(.purple)
            Text("Game Recording")
                .font(.title2)
                .fontWeight(.semibold)
            if let token = inviteToken {
                Text("Token: \(token)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
            Text("Coming soon…")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}



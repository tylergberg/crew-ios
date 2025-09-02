import SwiftUI

struct PartySettingsSheet: View {
    var onClose: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Party Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Settings UI coming soon…")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onClose?(); dismiss() }
                }
            }
        }
    }
}

struct EditThemeSheet: View {
    var onSaved: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager

    var body: some View {
        PartyThemeView(currentTheme: partyManager.currentTheme)
            .onDisappear {
                onSaved?()
            }
    }
}





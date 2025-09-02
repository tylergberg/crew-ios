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

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Edit Theme")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Theme editor coming soon…")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSaved?(); dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}

struct EditPartyTypeSheet: View {
    var onSaved: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("Edit Party Type")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Editor coming soon…")
                    .foregroundColor(.secondary)
                Spacer()
            }
            .padding()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { onSaved?(); dismiss() }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}



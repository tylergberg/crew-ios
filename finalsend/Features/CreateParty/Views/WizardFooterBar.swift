import SwiftUI

struct WizardFooterBar: View {
    let stepIndex: Int
    let totalSteps: Int
    let primaryTitle: String
    let primaryEnabled: Bool
    let showBack: Bool
    let showSkip: Bool
    let onBack: () -> Void
    let onSkip: () -> Void
    let onPrimary: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if showBack {
                    Button(action: onBack) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.titleDark)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                
                Spacer()
                
                if showSkip {
                    Button(action: onSkip) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.titleDark)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(Color.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                            )
                    }
                }
                
                Button(action: onPrimary) {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(primaryEnabled ? .white : .metaGrey)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(primaryEnabled ? Color(red: 0.93, green: 0.51, blue: 0.25) : Color.gray.opacity(0.3))
                        .cornerRadius(12)
                }
                .disabled(!primaryEnabled)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color.clear)
    }
}

#Preview {
    VStack {
        Spacer()
        WizardFooterBar(
            stepIndex: 2,
            totalSteps: 7,
            primaryTitle: "Continue",
            primaryEnabled: true,
            showBack: true,
            showSkip: false,
            onBack: {},
            onSkip: {},
            onPrimary: {}
        )
    }
    .background(Color.neutralBackground)
}

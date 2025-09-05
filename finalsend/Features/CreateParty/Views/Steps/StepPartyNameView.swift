import SwiftUI

struct StepPartyNameView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Trip Name")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("Choose a name that captures the vibe")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
            }
            
            // Party Name Field
            VStack(alignment: .leading, spacing: 8) {
                TextField("Taylor Swift's Bachelorette", text: $viewModel.draft.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.titleDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(.white)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                    )
                
                if !viewModel.isNameValid && !viewModel.draft.name.isEmpty {
                    Text("Name must be at least 2 characters.")
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    StepPartyNameView(viewModel: CreatePartyViewModel())
        .padding()
        .background(.white)
}

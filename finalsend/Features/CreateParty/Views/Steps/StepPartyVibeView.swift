import SwiftUI

struct StepPartyVibeView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Trip Vibe")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("Select tags that describe your trip")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
            }
            
            // Vibe Tags
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(CreatePartyViewModel.vibeTags, id: \.self) { tag in
                    TagToggle(
                        tag: tag,
                        isSelected: viewModel.draft.vibeTags.contains(tag)
                    ) {
                        viewModel.toggleVibeTag(tag)
                    }
                }
            }
            
            Spacer()
        }
    }
}

struct TagToggle: View {
    let tag: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(tag)
                .font(.system(size: 13, weight: .medium))
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .frame(maxWidth: .infinity)
                .background(
                    isSelected ? 
                        LinearGradient(
                            colors: [Color.brandBlue.opacity(0.9), Color.brandBlue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ) :
                        LinearGradient(
                            colors: [Color.white, Color.gray.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            isSelected ? Color.brandBlue.opacity(0.3) : Color.gray.opacity(0.2),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: isSelected ? Color.brandBlue.opacity(0.3) : Color.black.opacity(0.05),
                    radius: isSelected ? 4 : 2,
                    x: 0,
                    y: isSelected ? 2 : 1
                )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    StepPartyVibeView(viewModel: CreatePartyViewModel())
        .padding()
        .background(.white)
}

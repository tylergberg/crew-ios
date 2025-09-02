import SwiftUI

struct StepReviewCreateView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                                    Text("Trip Summary")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("Make sure everything looks good before creating")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
                }
                
                // Review Sections
                VStack(spacing: 20) {
                    // Party Name & Type
                    ReviewSection(title: "Party Details") {
                        ReviewRow(label: "Name", value: viewModel.draft.name)
                        ReviewRow(label: "Type", value: viewModel.draft.finalPartyType.capitalized)
                    }
                    
                    // Dates
                    if viewModel.draft.startDate != nil || viewModel.draft.endDate != nil {
                        ReviewSection(title: "Dates") {
                            if let startDate = viewModel.draft.startDate {
                                ReviewRow(label: "Start", value: formatDate(startDate))
                            }
                            if let endDate = viewModel.draft.endDate {
                                ReviewRow(label: "End", value: formatDate(endDate))
                            }
                        }
                    }
                    
                    // Location
                    if let cityId = viewModel.draft.cityId,
                       let city = viewModel.availableCities.first(where: { $0.id == cityId }) {
                        ReviewSection(title: "Location") {
                            ReviewRow(label: "City", value: city.displayName)
                            ReviewRow(label: "Country", value: city.country)
                        }
                    }
                    
                    // Vibe Tags
                    if !viewModel.draft.vibeTags.isEmpty {
                        ReviewSection(title: "Vibe") {
                            HStack {
                                Text("Tags:")
                                    .font(.subheadline)
                                    .foregroundColor(.metaGrey)
                                Spacer()
                                Text(viewModel.draft.vibeTags.joined(separator: ", "))
                                    .font(.subheadline)
                                    .foregroundColor(.titleDark)
                                    .multilineTextAlignment(.trailing)
                            }
                        }
                    }
                    
                    // Cover Photo
                    if viewModel.coverImage != nil {
                        ReviewSection(title: "Cover Photo") {
                            Text("Photo selected")
                                .font(.subheadline)
                                .foregroundColor(.metaGrey)
                        }
                    }
                }
                
                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    Text("Error: \(errorMessage)")
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.vertical, 8)
                }
                    }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ReviewSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.titleDark)
            
            VStack(spacing: 8) {
                content
            }
            .padding()
            .background(.white)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct ReviewRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.subheadline)
                .foregroundColor(.metaGrey)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(.titleDark)
                .multilineTextAlignment(.trailing)
        }
    }
}

#Preview {
    StepReviewCreateView(viewModel: CreatePartyViewModel())
        .padding()
        .background(.white)
}

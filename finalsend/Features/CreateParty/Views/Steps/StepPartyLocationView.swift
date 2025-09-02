import SwiftUI

struct StepPartyLocationView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Where is your party?")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("Optional. You can choose a city later.")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
            }
            
            // City Search
            VStack(alignment: .leading, spacing: 12) {
                TextField("Search cities...", text: $viewModel.searchQuery)
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
                
                if !viewModel.availableCities.isEmpty {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.availableCities) { city in
                                Button(action: {
                                    viewModel.draft.cityId = city.id
                                    viewModel.searchQuery = city.displayName
                                }) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(city.displayName)
                                            .font(.body)
                                            .foregroundColor(.titleDark)
                                        Text(city.country)
                                            .font(.caption)
                                            .foregroundColor(.metaGrey)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(.white)
                                    .cornerRadius(8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    StepPartyLocationView(viewModel: CreatePartyViewModel())
        .padding()
        .background(.white)
}

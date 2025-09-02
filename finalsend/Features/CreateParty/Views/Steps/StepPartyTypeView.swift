import SwiftUI

struct StepPartyTypeView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Trip Type")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("This helps us customize your experience")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
            }
            
            // Party Type Options
            VStack(spacing: 12) {
                ForEach(CreatePartyViewModel.partyTypeOptions, id: \.self) { type in
                    Button(action: {
                        viewModel.updatePartyType(type)
                    }) {
                        HStack {
                            Text(type)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(viewModel.draft.partyType == type ? .titleDark : .metaGrey)
                            
                            Spacer()
                            
                            if viewModel.draft.partyType == type {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.titleDark)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(viewModel.draft.partyType == type ? .yellow : .white)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            // Custom Trip Type Field
            if viewModel.showCustomPartyTypeField {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom trip type")
                        .font(.headline)
                        .foregroundColor(.titleDark)
                    
                    TextField("Enter custom trip type", text: $viewModel.draft.customPartyType)
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
                        .onChange(of: viewModel.draft.customPartyType) { customType in
                            viewModel.updateCustomPartyType(customType)
                        }
                }
            }
            

            
            Spacer(minLength: 0)
        }
        .padding(.bottom, 20) // Extra padding to ensure content doesn't get hidden
    }
}

#Preview {
    StepPartyTypeView(viewModel: CreatePartyViewModel())
        .padding()
        .background(.white)
}

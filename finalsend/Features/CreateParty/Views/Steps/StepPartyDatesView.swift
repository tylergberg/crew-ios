import SwiftUI

struct StepPartyDatesView: View {
    @ObservedObject var viewModel: CreatePartyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Trip Dates")
                    .font(Typography.title())
                    .foregroundColor(.titleDark)
                
                Text("You can set or edit this later")
                    .font(Typography.meta())
                    .foregroundColor(.metaGrey)
            }
            
            // Date Pickers
            VStack(spacing: 16) {
                DatePicker(
                    "Start Date",
                    selection: Binding(
                        get: { viewModel.draft.startDate ?? Date() },
                        set: { newStartDate in
                            viewModel.draft.startDate = newStartDate
                            // Auto-fill end date with start date if end date is not set or is before start date
                            if viewModel.draft.endDate == nil || viewModel.draft.endDate! < newStartDate {
                                viewModel.draft.endDate = newStartDate
                            }
                        }
                    ),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .accentColor(.brandBlue)
                
                DatePicker(
                    "End Date",
                    selection: Binding(
                        get: { viewModel.draft.endDate ?? Date() },
                        set: { viewModel.draft.endDate = $0 }
                    ),
                    in: (viewModel.draft.startDate ?? Date())...,
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .accentColor(.brandBlue)
            }
            
            // Validation Message
            if let validationMessage = viewModel.dateValidationMessage {
                Text(validationMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 8)
            }
            
            Spacer()
        }
    }
}

#Preview {
    StepPartyDatesView(viewModel: CreatePartyViewModel())
        .padding()
        .background(.white)
}

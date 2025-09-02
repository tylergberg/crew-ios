import SwiftUI

struct EditPartyDatesSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var partyManager: PartyManager
    let onSaved: () -> Void
    private let partyManagementService = PartyManagementService()
    @State private var startDate: Date = Date()
    @State private var endDate: Date = Date()
    @State private var isSaving = false
    @State private var validationMessage: String? = nil

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Edit Trip Dates")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.titleDark)
                    Text("Update when your trip starts and ends")
                        .font(.subheadline)
                        .foregroundColor(.metaGrey)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                VStack(spacing: 16) {
                    DatePicker(
                        "Start Date",
                        selection: $startDate,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .accentColor(Color.brandBlue)

                    DatePicker(
                        "End Date",
                        selection: $endDate,
                        in: startDate...,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .accentColor(Color.brandBlue)
                }
                .padding(.horizontal, 20)

                if let msg = validationMessage {
                    Text(msg)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                }

                Spacer()

                Button(action: saveDates) {
                    HStack {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                        } else {
                            Text("Save Changes")
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.brandBlue)
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .disabled(isSaving)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color.brandBlue)
                }
            }
        }
        .onAppear {
            startDate = partyManager.startDate
            endDate = max(partyManager.endDate, partyManager.startDate)
        }
    }

    private func saveDates() {
        guard endDate >= startDate else {
            validationMessage = "End date cannot be before start date"
            return
        }

        isSaving = true
        validationMessage = nil

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let updates: [String: Any] = [
            "start_date": formatter.string(from: startDate),
            "end_date": formatter.string(from: endDate)
        ]

        Task {
            do {
                let success = try await partyManagementService.updateParty(partyId: partyManager.partyId, updates: updates)
                if success {
                    partyManager.startDate = startDate
                    partyManager.endDate = endDate
                    onSaved()
                    dismiss()
                }
            } catch {
                validationMessage = "Failed to save dates. Please try again."
            }
            isSaving = false
        }
    }
}

#Preview {
    EditPartyDatesSheet(onSaved: {})
        .environmentObject(PartyManager.mock)
}



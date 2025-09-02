import SwiftUI

struct TransportItemFormSheet: View {
    @ObservedObject var transportStore: TransportStore
    let partyId: UUID
    let currentUserId: UUID
    let type: TransportationType
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var description = ""
    @State private var date: Date = Date()
    @State private var time: Date = Date()
    @State private var meetingPoint = ""
    @State private var capacity: Int = 4
    @State private var url = ""
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Transportation Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Schedule") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                }
                
                Section("Location & Details") {
                    TextField("Meeting Point (optional)", text: $meetingPoint)
                    
                    Stepper("Capacity: \(capacity)", value: $capacity, in: 1...10)
                    
                    TextField("URL (optional)", text: $url)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
            }
            .navigationTitle("Add \(type.displayName)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task {
                            await saveTransportation()
                        }
                    }
                    .disabled(!isValidForm || isLoading)
                }
            }
        }
    }
    
    private var isValidForm: Bool {
        !title.isEmpty
    }
    
    private func saveTransportation() async {
        isLoading = true
        
        // Combine date and time
        let calendar = Calendar.current
        let combinedDate = calendar.date(
            bySettingHour: calendar.component(.hour, from: time),
            minute: calendar.component(.minute, from: time),
            second: 0,
            of: date
        ) ?? date
        
        let transportation = Transportation(
            partyId: partyId,
            type: type,
            title: title,
            description: description.isEmpty ? nil : description,
            date: date,
            time: combinedDate,
            meetingPoint: meetingPoint.isEmpty ? nil : meetingPoint,
            capacity: capacity,
            url: url.isEmpty ? nil : url,
            createdBy: currentUserId
        )
        
        await transportStore.createTransportation(transportation)
        
        isLoading = false
        dismiss()
    }
}

#Preview {
    TransportItemFormSheet(
        transportStore: TransportStore(
            transportService: TransportService(supabase: SupabaseManager.shared.client)
        ),
        partyId: UUID(),
        currentUserId: UUID(),
        type: .carpool
    )
}

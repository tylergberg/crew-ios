import SwiftUI

// MARK: - Add Event Sheet
struct AddEventSheet: View {
    let partyId: String
    let currentUserId: String
    let cityTimezone: String?
    let onEventAdded: (ItineraryEvent) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var location = ""
    @State private var locationUrl = ""
    @State private var imageUrl = ""
    @State private var selectedDate = Date()
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    
    private var timezoneInfo: (name: String, abbr: String) {
        if let timezone = cityTimezone {
            return TimezoneUtils.getTimezoneDisplay(timezone)
        }
        return ("Local Time", "LT")
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section("Location") {
                    TextField("Location (Optional)", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Location URL (Optional)", text: $locationUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Date & Time") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    if let timezone = cityTimezone {
                        HStack {
                            Text("Timezone")
                            Spacer()
                            Text("\(timezoneInfo.name) (\(timezoneInfo.abbr))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Image (Optional)") {
                    TextField("Image URL", text: $imageUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Add Event")
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
                            await saveEvent()
                        }
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
        .onAppear {
            setupDefaultTimes()
        }
    }
    
    private func setupDefaultTimes() {
        let now = Date()
        selectedDate = now
        
        // Set default start time to next hour
        let calendar = Calendar.current
        let nextHour = calendar.date(byAdding: .hour, value: 1, to: now) ?? now
        startTime = nextHour
        
        // Set default end time to 2 hours after start
        let twoHoursLater = calendar.date(byAdding: .hour, value: 2, to: nextHour) ?? nextHour
        endTime = twoHoursLater
    }
    
    private func saveEvent() async {
        guard !title.isEmpty else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            // Create the event using our existing timezone utilities
            let event = ItineraryEvent(
                partyId: UUID(uuidString: partyId) ?? UUID(),
                title: title,
                description: description.isEmpty ? nil : description,
                location: location.isEmpty ? nil : location,
                locationUrl: locationUrl.isEmpty ? nil : locationUrl,
                imageUrl: imageUrl.isEmpty ? nil : imageUrl,
                createdBy: UUID(uuidString: currentUserId) ?? UUID(),
                startTime: combineDateAndTime(selectedDate, startTime),
                endTime: combineDateAndTime(selectedDate, endTime)
            )
            
            onEventAdded(event)
            dismiss()
            
        } catch {
            errorMessage = "Failed to save event: \(error.localizedDescription)"
        }
        
        isSubmitting = false
    }
    
    private func combineDateAndTime(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = 0
        
        return calendar.date(from: combinedComponents) ?? date
    }
}

// MARK: - Edit Event Sheet
struct EditEventSheet: View {
    let event: ItineraryEvent
    let cityTimezone: String?
    let onEventUpdated: (ItineraryEvent) -> Void
    let onEventDeleted: (UUID) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var description: String
    @State private var location: String
    @State private var locationUrl: String
    @State private var imageUrl: String
    @State private var selectedDate: Date
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showDeleteAlert = false
    
    private var timezoneInfo: (name: String, abbr: String) {
        if let timezone = cityTimezone {
            return TimezoneUtils.getTimezoneDisplay(timezone)
        }
        return ("Local Time", "LT")
    }
    
    init(event: ItineraryEvent, cityTimezone: String?, onEventUpdated: @escaping (ItineraryEvent) -> Void, onEventDeleted: @escaping (UUID) -> Void) {
        self.event = event
        self.cityTimezone = cityTimezone
        self.onEventUpdated = onEventUpdated
        self.onEventDeleted = onEventDeleted
        
        // Initialize state with current event values
        self._title = State(initialValue: event.title)
        self._description = State(initialValue: event.description ?? "")
        self._location = State(initialValue: event.location ?? "")
        self._locationUrl = State(initialValue: event.locationUrl ?? "")
        self._imageUrl = State(initialValue: event.imageUrl ?? "")
        
        // Set date and time from event
        if let startTime = event.startTime {
            self._selectedDate = State(initialValue: startTime)
            self._startTime = State(initialValue: startTime)
        } else {
            self._selectedDate = State(initialValue: Date())
            self._startTime = State(initialValue: Date())
        }
        
        if let endTime = event.endTime {
            self._endTime = State(initialValue: endTime)
        } else {
            self._endTime = State(initialValue: Date())
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Event Details") {
                    TextField("Event Title", text: $title)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }
                
                Section("Location") {
                    TextField("Location (Optional)", text: $location)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    TextField("Location URL (Optional)", text: $locationUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                Section("Date & Time") {
                    DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                    
                    DatePicker("Start Time", selection: $startTime, displayedComponents: .hourAndMinute)
                    
                    DatePicker("End Time", selection: $endTime, displayedComponents: .hourAndMinute)
                    
                    if let timezone = cityTimezone {
                        HStack {
                            Text("Timezone")
                            Spacer()
                            Text("\(timezoneInfo.name) (\(timezoneInfo.abbr))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Image (Optional)") {
                    TextField("Image URL", text: $imageUrl)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                Section {
                    Button("Delete Event") {
                        showDeleteAlert = true
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Edit Event")
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
                            await updateEvent()
                        }
                    }
                    .disabled(title.isEmpty || isSubmitting)
                }
            }
        }
        .alert("Delete Event", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteEvent()
            }
        } message: {
            Text("Are you sure you want to delete this event? This action cannot be undone.")
        }
    }
    
    private func updateEvent() async {
        guard !title.isEmpty else { return }
        
        isSubmitting = true
        errorMessage = nil
        
        do {
            let updatedEvent = ItineraryEvent(
                id: event.id,
                partyId: event.partyId,
                title: title,
                description: description.isEmpty ? nil : description,
                location: location.isEmpty ? nil : location,
                locationUrl: locationUrl.isEmpty ? nil : locationUrl,
                imageUrl: imageUrl.isEmpty ? nil : imageUrl,
                createdAt: event.createdAt,
                createdBy: event.createdBy,
                updatedAt: Date(),
                cityId: event.cityId,
                startTime: combineDateAndTime(selectedDate, startTime),
                endTime: combineDateAndTime(selectedDate, endTime),
                latitude: event.latitude,
                longitude: event.longitude
            )
            
            onEventUpdated(updatedEvent)
            dismiss()
            
        } catch {
            errorMessage = "Failed to update event: \(error.localizedDescription)"
        }
        
        isSubmitting = false
    }
    
    private func deleteEvent() {
        onEventDeleted(event.id)
        dismiss()
    }
    
    private func combineDateAndTime(_ date: Date, _ time: Date) -> Date {
        let calendar = Calendar.current
        
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        var combinedComponents = DateComponents()
        combinedComponents.year = dateComponents.year
        combinedComponents.month = dateComponents.month
        combinedComponents.day = dateComponents.day
        combinedComponents.hour = timeComponents.hour
        combinedComponents.minute = timeComponents.minute
        combinedComponents.second = 0
        
        return calendar.date(from: combinedComponents) ?? date
    }
}

#Preview {
    AddEventSheet(
        partyId: "test-party-id",
        currentUserId: "test-user-id",
        cityTimezone: "America/New_York",
        onEventAdded: { _ in }
    )
}





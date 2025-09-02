import SwiftUI

struct FlightFormSheet: View {
    @ObservedObject var flightsStore: FlightsStore
    let partyId: UUID
    let currentUserId: UUID
    let existingFlight: Flight?
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var airline = ""
    @State private var flightNumber = ""
    @State private var departureAirportCode = ""
    @State private var departureAirportName = ""
    @State private var arrivalAirportCode = ""
    @State private var arrivalAirportName = ""
    @State private var departureTime = Date()
    @State private var arrivalTime = Date().addingTimeInterval(3600 * 2)
    @State private var direction: FlightDirection = .arrival
    @State private var notes = ""
    @State private var departureTimezone = "America/New_York"
    @State private var arrivalTimezone = "America/New_York"
    @State private var isLoading = false
    
    var isEditing: Bool {
        existingFlight != nil
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Flight Details") {
                    TextField("Airline", text: $airline)
                    TextField("Flight Number", text: $flightNumber)
                    
                    Picker("Direction", selection: $direction) {
                        ForEach(FlightDirection.allCases, id: \.self) { direction in
                            Text(direction.displayName).tag(direction)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Departure") {
                    TextField("Airport Code (e.g., YYZ)", text: $departureAirportCode)
                        .textInputAutocapitalization(.characters)
                    TextField("Airport Name (optional)", text: $departureAirportName)
                    
                    DatePicker("Departure Time", selection: $departureTime, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Departure Timezone", selection: $departureTimezone) {
                        ForEach(TimezoneOption.commonTimezones, id: \.value) { timezone in
                            Text(timezone.displayName).tag(timezone.value)
                        }
                    }
                }
                
                Section("Arrival") {
                    TextField("Airport Code (e.g., AUS)", text: $arrivalAirportCode)
                        .textInputAutocapitalization(.characters)
                    TextField("Airport Name (optional)", text: $arrivalAirportName)
                    
                    DatePicker("Arrival Time", selection: $arrivalTime, displayedComponents: [.date, .hourAndMinute])
                    
                    Picker("Arrival Timezone", selection: $arrivalTimezone) {
                        ForEach(TimezoneOption.commonTimezones, id: \.value) { timezone in
                            Text(timezone.displayName).tag(timezone.value)
                        }
                    }
                }
                
                Section("Additional Info") {
                    TextField("Notes (optional)", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle(isEditing ? "Edit Flight" : "Add Flight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isEditing ? "Update" : "Save") {
                        Task {
                            if isEditing {
                                await updateFlight()
                            } else {
                                await saveFlight()
                            }
                        }
                    }
                    .disabled(!isValidForm || isLoading)
                }
            }
        }
        .onAppear {
            if let flight = existingFlight {
                loadFlightData(flight)
            }
        }
    }
    
    private var isValidForm: Bool {
        !airline.isEmpty &&
        !flightNumber.isEmpty &&
        !departureAirportCode.isEmpty &&
        !arrivalAirportCode.isEmpty &&
        departureTime < arrivalTime
    }
    
    private func loadFlightData(_ flight: Flight) {
        airline = flight.airline
        flightNumber = flight.flightNumber
        departureAirportCode = flight.departureAirportCode
        departureAirportName = flight.departureAirportName ?? ""
        arrivalAirportCode = flight.arrivalAirportCode
        arrivalAirportName = flight.arrivalAirportName ?? ""
        departureTime = flight.departureTime
        arrivalTime = flight.arrivalTime
        direction = flight.direction
        notes = flight.notes ?? ""
        departureTimezone = flight.departureTimezone ?? "America/New_York"
        arrivalTimezone = flight.arrivalTimezone ?? "America/New_York"
    }
    
    private func saveFlight() async {
        isLoading = true
        
        // Create the flight with the times as-is (no timezone conversion)
        let flight = Flight(
            partyId: partyId,
            flightNumber: flightNumber,
            airline: airline,
            departureAirportCode: departureAirportCode.uppercased(),
            departureAirportName: departureAirportName.isEmpty ? nil : departureAirportName,
            arrivalAirportCode: arrivalAirportCode.uppercased(),
            arrivalAirportName: arrivalAirportName.isEmpty ? nil : arrivalAirportName,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            direction: direction,
            notes: notes.isEmpty ? nil : notes,
            createdBy: currentUserId,
            departureTimezone: departureTimezone,
            arrivalTimezone: arrivalTimezone
        )
        
        await flightsStore.createFlight(flight)
        
        isLoading = false
        dismiss()
    }
    
    private func updateFlight() async {
        guard let existingFlight = existingFlight else { return }
        
        isLoading = true
        
        // Update the flight with the times as-is (no timezone conversion)
        let updatedFlight = Flight(
            id: existingFlight.id,
            partyId: partyId,
            flightNumber: flightNumber,
            airline: airline,
            departureAirportCode: departureAirportCode.uppercased(),
            departureAirportName: departureAirportName.isEmpty ? nil : departureAirportName,
            arrivalAirportCode: arrivalAirportCode.uppercased(),
            arrivalAirportName: arrivalAirportName.isEmpty ? nil : arrivalAirportName,
            departureTime: departureTime,
            arrivalTime: arrivalTime,
            direction: direction,
            notes: notes.isEmpty ? nil : notes,
            createdBy: currentUserId,
            createdAt: existingFlight.createdAt,
            updatedAt: Date(),
            departureTimezone: departureTimezone,
            arrivalTimezone: arrivalTimezone
        )
        
        await flightsStore.updateFlight(updatedFlight)
        
        isLoading = false
        dismiss()
    }
}

#Preview {
    FlightFormSheet(
        flightsStore: FlightsStore(
            flightsService: TransportFlightsService(supabase: SupabaseManager.shared.client),
            currentUserId: UUID()
        ),
        partyId: UUID(),
        currentUserId: UUID(),
        existingFlight: nil
    )
}

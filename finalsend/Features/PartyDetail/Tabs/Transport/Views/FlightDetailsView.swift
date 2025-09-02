import SwiftUI

struct FlightDetailsView: View {
    let flight: Flight
    let passengers: [FlightPassenger]
    let currentUserId: UUID
    let onEdit: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var showingActionSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Flight Summary Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("\(flight.airline) \(flight.flightNumber)")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // Status indicator
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title2)
                        }
                        
                        Text("\(flight.departureAirportCode) → \(flight.arrivalAirportCode)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Flight Details Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Flight Details")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        HStack(spacing: 20) {
                            // Departure
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Departure")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(flight.departureAirportCode)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    if let departureName = flight.departureAirportName {
                                        Text(departureName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(flight.departureDateString)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(flight.departureTimezoneDisplay)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            // Airplane icon
                            Image(systemName: "airplane")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .rotationEffect(.degrees(0))
                            
                            Spacer()
                            
                            // Arrival
                            VStack(alignment: .trailing, spacing: 8) {
                                Text("Arrival")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(flight.arrivalAirportCode)
                                        .font(.title3)
                                        .fontWeight(.bold)
                                    
                                    if let arrivalName = flight.arrivalAirportName {
                                        Text(arrivalName)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(flight.arrivalDateString)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                    
                                    Text(flight.arrivalTimezoneDisplay)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        
                        if let notes = flight.notes, !notes.isEmpty {
                            Divider()
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Notes")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Text(notes)
                                    .font(.body)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Passengers Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Passengers (\(passengers.count))")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(passengers) { passenger in
                                PassengerRow(
                                    passenger: passenger,
                                    isCurrentUser: passenger.userId == currentUserId
                                )
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Join/Leave Button at bottom
                    VStack(spacing: 12) {
                        if let currentUserPassenger = passengers.first(where: { $0.userId == currentUserId }) {
                            Button("Leave Flight") {
                                // Handle leave logic
                            }
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.red)
                            .cornerRadius(12)
                        } else {
                            Button("Join Flight") {
                                // Handle join logic
                            }
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding()
            }
            .navigationTitle("Flight Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingActionSheet = true }) {
                        Image(systemName: "ellipsis")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .actionSheet(isPresented: $showingActionSheet) {
            ActionSheet(
                title: Text("Flight Options"),
                buttons: [
                    .default(Text("Edit Flight")) {
                        onEdit()
                    },
                    .destructive(Text("Delete Flight")) {
                        showingDeleteAlert = true
                    },
                    .cancel()
                ]
            )
        }
        .alert("Delete Flight", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                // Handle delete logic
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this flight? This action cannot be undone.")
        }
    }
}

struct PassengerRow: View {
    let passenger: FlightPassenger
    let isCurrentUser: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            if let avatarUrl = passenger.avatarUrl, !avatarUrl.isEmpty {
                AsyncImage(url: URL(string: avatarUrl)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Text(passenger.initials)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
                .frame(width: 40, height: 40)
                .clipShape(Circle())
            } else {
                Text(passenger.initials)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .frame(width: 40, height: 40)
                    .background(Color.gray)
                    .clipShape(Circle())
            }
            
            // Name
            VStack(alignment: .leading, spacing: 2) {
                Text(passenger.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if isCurrentUser {
                    Text("You")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
    }
}

#Preview {
    let sampleFlight = Flight(
        partyId: UUID(),
        flightNumber: "AC1739",
        airline: "Air Canada",
        departureAirportCode: "YYZ",
        departureAirportName: "Toronto Pearson",
        arrivalAirportCode: "AUS",
        arrivalAirportName: "Austin-Bergstrom",
        departureTime: Date(),
        arrivalTime: Date().addingTimeInterval(3600 * 2),
        direction: .arrival,
        notes: "Direct flight to Austin",
        createdBy: UUID(),
        departureTimezone: "America/New_York",
        arrivalTimezone: "America/Chicago"
    )
    
    let samplePassengers = [
        FlightPassenger(
            id: UUID(),
            flightId: UUID(),
            userId: UUID(),
            partyId: UUID(),
            profile: TransportProfile(
                id: "1",
                fullName: "Tyler Greenberg",
                avatarUrl: nil
            ),
            isCurrentUser: true
        ),
        FlightPassenger(
            id: UUID(),
            flightId: UUID(),
            userId: UUID(),
            partyId: UUID(),
            profile: TransportProfile(
                id: "2",
                fullName: "Rafa",
                avatarUrl: nil
            ),
            isCurrentUser: false
        ),
        FlightPassenger(
            id: UUID(),
            flightId: UUID(),
            userId: UUID(),
            partyId: UUID(),
            profile: TransportProfile(
                id: "3",
                fullName: "Aaron Fried",
                avatarUrl: nil
            ),
            isCurrentUser: false
        )
    ]
    
    FlightDetailsView(
        flight: sampleFlight,
        passengers: samplePassengers,
        currentUserId: UUID(),
        onEdit: {}
    )
}

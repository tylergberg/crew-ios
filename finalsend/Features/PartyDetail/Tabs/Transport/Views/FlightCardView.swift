import SwiftUI

struct FlightCardView: View {
    let flight: Flight
    let passengers: [FlightPassenger]
    let onTap: () -> Void
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Flight header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(flight.airline) \(flight.flightNumber)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("\(flight.departureAirportCode) → \(flight.arrivalAirportCode)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let departureName = flight.departureAirportName,
                           let arrivalName = flight.arrivalAirportName {
                            Text("\(departureName) → \(arrivalName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Times - Stacked vertically with timezone codes
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Depart:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(flight.departureDateString) \(flight.departureTimezoneDisplay)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    
                    HStack {
                        Text("Arrive:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(flight.arrivalDateString) \(flight.arrivalTimezoneDisplay)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }
                
                // Passengers
                HStack {
                    Text("Passengers (\(passengers.count))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    HStack(spacing: -8) {
                        ForEach(Array(passengers.prefix(3)), id: \.id) { passenger in
                            if let avatarUrl = passenger.avatarUrl, !avatarUrl.isEmpty {
                                AsyncImage(url: URL(string: avatarUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Text(passenger.initials)
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                        .frame(width: 24, height: 24)
                                        .background(Color.gray)
                                        .clipShape(Circle())
                                }
                                .frame(width: 24, height: 24)
                                .clipShape(Circle())
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1)
                                )
                            } else {
                                Text(passenger.initials)
                                    .font(.caption2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.white)
                                    .frame(width: 24, height: 24)
                                    .background(Color.gray)
                                    .clipShape(Circle())
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: 1)
                                    )
                            }
                        }
                        
                        if passengers.count > 3 {
                            Text("+\(passengers.count - 3)")
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(width: 24, height: 24)
                                .background(Color.gray.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .padding(16)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
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
        notes: nil,
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
        )
    ]
    
    FlightCardView(
        flight: sampleFlight,
        passengers: samplePassengers,
        onTap: {},
        onEdit: {}
    )
    .padding()
    .background(Color(.systemGroupedBackground))
}

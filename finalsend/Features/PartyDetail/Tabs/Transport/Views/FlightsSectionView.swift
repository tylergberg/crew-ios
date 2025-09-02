import SwiftUI

struct FlightsSectionView: View {
    @ObservedObject var flightsStore: FlightsStore
    let partyId: UUID
    let currentUserId: UUID
    let currentUserRole: UserRole
    let destinationCity: String?
    
    @State private var showingFlightForm = false
    @State private var selectedFlight: Flight?
    @State private var editingFlight: Flight?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Going to section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Going to \(destinationCity ?? "Destination")")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            editingFlight = nil
                            showingFlightForm = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.primary)
                                .clipShape(Circle())
                        }
                    }
                    
                    let arrivalFlights = flightsStore.getArrivalFlights()
                    if arrivalFlights.isEmpty {
                        EmptyFlightSection(direction: .arrival)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(arrivalFlights) { flight in
                                    FlightCardView(
                                        flight: flight,
                                        passengers: flightsStore.getPassengers(for: flight.id),
                                        onTap: { selectedFlight = flight },
                                        onEdit: {
                                            editingFlight = flight
                                            showingFlightForm = true
                                        }
                                    )
                                    .frame(width: 320)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                
                // Leaving section
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Leaving \(destinationCity ?? "Destination")")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Spacer()
                        
                        Button(action: {
                            editingFlight = nil
                            showingFlightForm = true
                        }) {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.primary)
                                .clipShape(Circle())
                        }
                    }
                    
                    let departureFlights = flightsStore.getDepartureFlights()
                    if departureFlights.isEmpty {
                        EmptyFlightSection(direction: .departure)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(departureFlights) { flight in
                                    FlightCardView(
                                        flight: flight,
                                        passengers: flightsStore.getPassengers(for: flight.id),
                                        onTap: { selectedFlight = flight },
                                        onEdit: {
                                            editingFlight = flight
                                            showingFlightForm = true
                                        }
                                    )
                                    .frame(width: 320)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
        .sheet(isPresented: $showingFlightForm) {
            FlightFormSheet(
                flightsStore: flightsStore,
                partyId: partyId,
                currentUserId: currentUserId,
                existingFlight: editingFlight
            )
        }
        .sheet(item: $selectedFlight) { flight in
            FlightDetailsView(
                flight: flight,
                passengers: flightsStore.getPassengers(for: flight.id),
                currentUserId: currentUserId,
                onEdit: {
                    editingFlight = flight
                    selectedFlight = nil
                    showingFlightForm = true
                }
            )
        }
    }
}

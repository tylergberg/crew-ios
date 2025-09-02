import Foundation
import SwiftUI

@MainActor
class FlightsStore: ObservableObject {
    @Published var flights: [Flight] = []
    @Published var flightPassengers: [UUID: [FlightPassenger]] = [:]
    @Published var isLoading = false
    @Published var error: Error?
    
    private let flightsService: TransportFlightsService
    private let currentUserId: UUID
    
    init(flightsService: TransportFlightsService, currentUserId: UUID) {
        self.flightsService = flightsService
        self.currentUserId = currentUserId
    }
    
    // MARK: - Public Methods
    
    func loadFlights(partyId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            flights = try await flightsService.fetchFlights(partyId: partyId)
            
            // Load passengers for each flight
            for flight in flights {
                await loadPassengers(for: flight.id)
            }
        } catch {
            self.error = error
            print("❌ Error loading flights: \(error)")
        }
        
        isLoading = false
    }
    
    func createFlight(_ flight: Flight) async {
        do {
            let newFlight = try await flightsService.createFlight(flight)
            flights.append(newFlight)
            flights.sort { $0.departureTime < $1.departureTime }
        } catch {
            self.error = error
            print("❌ Error creating flight: \(error)")
        }
    }
    
    func updateFlight(_ flight: Flight) async {
        do {
            let updatedFlight = try await flightsService.updateFlight(flight)
            if let index = flights.firstIndex(where: { $0.id == flight.id }) {
                flights[index] = updatedFlight
            }
        } catch {
            self.error = error
            print("❌ Error updating flight: \(error)")
        }
    }
    
    func deleteFlight(_ flightId: UUID) async {
        do {
            try await flightsService.deleteFlight(flightId)
            flights.removeAll { $0.id == flightId }
            flightPassengers.removeValue(forKey: flightId)
        } catch {
            self.error = error
            print("❌ Error deleting flight: \(error)")
        }
    }
    
    func joinFlight(_ flightId: UUID, partyId: UUID) async {
        do {
            let passenger = try await flightsService.joinFlight(
                flightId: flightId,
                userId: currentUserId,
                partyId: partyId
            )
            
            // Add passenger to the list
            if var passengers = flightPassengers[flightId] {
                passengers.append(passenger)
                flightPassengers[flightId] = passengers
            } else {
                flightPassengers[flightId] = [passenger]
            }
        } catch {
            self.error = error
            print("❌ Error joining flight: \(error)")
        }
    }
    
    func leaveFlight(_ flightId: UUID) async {
        do {
            try await flightsService.leaveFlight(flightId: flightId, userId: currentUserId)
            
            // Remove passenger from the list
            if var passengers = flightPassengers[flightId] {
                passengers.removeAll { $0.userId == currentUserId }
                flightPassengers[flightId] = passengers
            }
        } catch {
            self.error = error
            print("❌ Error leaving flight: \(error)")
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadPassengers(for flightId: UUID) async {
        do {
            let passengers = try await flightsService.fetchFlightPassengers(flightId: flightId)
            
            // Mark current user
            let passengersWithCurrentUser = passengers.map { passenger in
                var updatedPassenger = passenger
                updatedPassenger.isCurrentUser = passenger.userId == currentUserId
                return updatedPassenger
            }
            
            flightPassengers[flightId] = passengersWithCurrentUser
        } catch {
            print("❌ Error loading passengers for flight \(flightId): \(error)")
        }
    }
    
    func getPassengers(for flightId: UUID) -> [FlightPassenger] {
        return flightPassengers[flightId] ?? []
    }
    
    func isUserOnFlight(_ flightId: UUID) -> Bool {
        guard let passengers = flightPassengers[flightId] else { return false }
        return passengers.contains { $0.userId == currentUserId }
    }
    
    func getFlightsByDirection(_ direction: FlightDirection) -> [Flight] {
        return flights.filter { $0.direction == direction }
    }
    
    func getArrivalFlights() -> [Flight] {
        return getFlightsByDirection(.arrival)
    }
    
    func getDepartureFlights() -> [Flight] {
        return getFlightsByDirection(.departure)
    }
}

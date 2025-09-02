import Foundation
import Supabase

@MainActor
class TransportFlightsService: ObservableObject {
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }
    
    // MARK: - Flights
    
    func fetchFlights(partyId: UUID) async throws -> [Flight] {
        let response: [Flight] = try await supabase
            .from("flights")
            .select()
            .eq("party_id", value: partyId)
            .order("departure_time", ascending: true)
            .execute()
            .value
        
        return response
    }
    
    func createFlight(_ flight: Flight) async throws -> Flight {
        let response: Flight = try await supabase
            .from("flights")
            .insert(flight)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func updateFlight(_ flight: Flight) async throws -> Flight {
        let response: Flight = try await supabase
            .from("flights")
            .update(flight)
            .eq("id", value: flight.id)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func deleteFlight(_ flightId: UUID) async throws {
        try await supabase
            .from("flights")
            .delete()
            .eq("id", value: flightId)
            .execute()
    }
    
    // MARK: - Flight Passengers
    
    func fetchFlightPassengers(flightId: UUID) async throws -> [FlightPassenger] {
        // First, get the basic passenger data
        let passengerResponse: [FlightPassenger] = try await supabase
            .from("flight_passengers")
            .select()
            .eq("flight_id", value: flightId)
            .execute()
            .value
        
        // Then, get profile data for each passenger
        var passengersWithProfiles: [FlightPassenger] = []
        
        for passenger in passengerResponse {
            do {
                let profileResponse: TransportProfile? = try await supabase
                    .from("profiles")
                    .select("id, full_name, avatar_url")
                    .eq("id", value: passenger.userId)
                    .single()
                    .execute()
                    .value
                
                var updatedPassenger = passenger
                updatedPassenger.profile = profileResponse
                passengersWithProfiles.append(updatedPassenger)
            } catch {
                print("❌ Error fetching profile for passenger \(passenger.userId): \(error)")
                // Add passenger without profile
                passengersWithProfiles.append(passenger)
            }
        }
        
        return passengersWithProfiles
    }
    
    func joinFlight(flightId: UUID, userId: UUID, partyId: UUID) async throws -> FlightPassenger {
        let passenger = FlightPassenger(
            flightId: flightId,
            userId: userId,
            partyId: partyId
        )
        
        let response: FlightPassenger = try await supabase
            .from("flight_passengers")
            .insert(passenger)
            .select()
            .single()
            .execute()
            .value
        
        return response
    }
    
    func leaveFlight(flightId: UUID, userId: UUID) async throws {
        try await supabase
            .from("flight_passengers")
            .delete()
            .eq("flight_id", value: flightId)
            .eq("user_id", value: userId)
            .execute()
    }
    
    func isUserOnFlight(flightId: UUID, userId: UUID) async throws -> Bool {
        let response: [FlightPassenger] = try await supabase
            .from("flight_passengers")
            .select()
            .eq("flight_id", value: flightId)
            .eq("user_id", value: userId)
            .execute()
            .value
        
        return !response.isEmpty
    }
}

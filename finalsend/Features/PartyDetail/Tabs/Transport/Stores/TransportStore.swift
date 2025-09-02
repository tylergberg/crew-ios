import Foundation
import SwiftUI

@MainActor
class TransportStore: ObservableObject {
    @Published var transportations: [Transportation] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let transportService: TransportService
    
    init(transportService: TransportService) {
        self.transportService = transportService
    }
    
    func loadTransportations(partyId: UUID) async {
        isLoading = true
        error = nil
        
        do {
            transportations = try await transportService.fetchTransportations(partyId: partyId)
        } catch {
            self.error = error
            print("❌ Error loading transportations: \(error)")
        }
        
        isLoading = false
    }
    
    func createTransportation(_ transportation: Transportation) async {
        do {
            let newTransportation = try await transportService.createTransportation(transportation)
            transportations.insert(newTransportation, at: 0)
        } catch {
            self.error = error
            print("❌ Error creating transportation: \(error)")
        }
    }
    
    func updateTransportation(_ transportation: Transportation) async {
        do {
            let updatedTransportation = try await transportService.updateTransportation(transportation)
            if let index = transportations.firstIndex(where: { $0.id == transportation.id }) {
                transportations[index] = updatedTransportation
            }
        } catch {
            self.error = error
            print("❌ Error updating transportation: \(error)")
        }
    }
    
    func deleteTransportation(_ transportationId: UUID) async {
        do {
            try await transportService.deleteTransportation(transportationId)
            transportations.removeAll { $0.id == transportationId }
        } catch {
            self.error = error
            print("❌ Error deleting transportation: \(error)")
        }
    }
    
    func getTransportationsByType(_ type: TransportationType) -> [Transportation] {
        return transportations.filter { $0.type == type }
    }
}

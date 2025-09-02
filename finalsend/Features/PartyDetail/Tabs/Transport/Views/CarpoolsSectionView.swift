import SwiftUI

struct CarpoolsSectionView: View {
    @ObservedObject var transportStore: TransportStore
    
    let partyId: UUID
    let currentUserId: UUID
    let currentUserRole: UserRole
    
    @State private var showingTransportForm = false
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Header
                HStack {
                    Text("Carpools & Rides")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Button(action: {
                        showingTransportForm = true
                    }) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                
                // Carpools list
                let carpools = transportStore.getTransportationsByType(.carpool)
                
                if carpools.isEmpty {
                    EmptyCarpoolsSection()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(carpools) { carpool in
                            CarpoolCardView(
                                carpool: carpool,
                                onDelete: {
                                    Task {
                                        await transportStore.deleteTransportation(carpool.id)
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
            }
        }
        .sheet(isPresented: $showingTransportForm) {
            TransportItemFormSheet(
                transportStore: transportStore,
                partyId: partyId,
                currentUserId: currentUserId,
                type: .carpool
            )
        }
    }
}

struct EmptyCarpoolsSection: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "car.fill")
                .font(.system(size: 32))
                .foregroundColor(.gray.opacity(0.5))
            
            Text("No carpools yet")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Add a carpool to coordinate rides")
                .font(.subheadline)
                .foregroundColor(.gray.opacity(0.7))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal, 16)
    }
}

struct CarpoolCardView: View {
    let carpool: Transportation
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(carpool.title)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    if let description = carpool.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                        .font(.caption)
                }
            }
            
            if let date = carpool.date {
                HStack {
                    Image(systemName: "calendar")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let meetingPoint = carpool.meetingPoint {
                HStack {
                    Image(systemName: "location")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text(meetingPoint)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let capacity = carpool.capacity {
                HStack {
                    Image(systemName: "person.3")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Text("Capacity: \(capacity)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    CarpoolsSectionView(
        transportStore: TransportStore(
            transportService: TransportService(supabase: SupabaseManager.shared.client)
        ),
        partyId: UUID(),
        currentUserId: UUID(),
        currentUserRole: .attendee
    )
}

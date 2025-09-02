import SwiftUI

struct TransportTabView: View {
    let partyId: UUID
    let currentUserId: UUID
    let currentUserRole: UserRole
    let destinationCity: String?
    let partyStartDate: Date
    let partyEndDate: Date
    var onDismiss: (() -> Void)?
    
    @StateObject private var flightsStore: FlightsStore
    @StateObject private var transportStore: TransportStore
    @State private var selectedTab = 0
    
    init(
        partyId: UUID,
        currentUserId: UUID,
        currentUserRole: UserRole,
        destinationCity: String?,
        partyStartDate: Date,
        partyEndDate: Date,
        onDismiss: (() -> Void)? = nil
    ) {
        self.partyId = partyId
        self.currentUserId = currentUserId
        self.currentUserRole = currentUserRole
        self.destinationCity = destinationCity
        self.partyStartDate = partyStartDate
        self.partyEndDate = partyEndDate
        self.onDismiss = onDismiss
        
        let flightsService = TransportFlightsService(supabase: SupabaseManager.shared.client)
        let transportService = TransportService(supabase: SupabaseManager.shared.client)
        
        self._flightsStore = StateObject(wrappedValue: FlightsStore(
            flightsService: flightsService,
            currentUserId: currentUserId
        ))
        self._transportStore = StateObject(wrappedValue: TransportStore(
            transportService: transportService
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Segmented Control
                Picker("Transport Type", selection: $selectedTab) {
                    Text("Flights").tag(0)
                    Text("Carpools").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top)
                
                // Content
                if selectedTab == 0 {
                    FlightsSectionView(
                        flightsStore: flightsStore,
                        partyId: partyId,
                        currentUserId: currentUserId,
                        currentUserRole: currentUserRole,
                        destinationCity: destinationCity
                    )
                } else {
                    CarpoolsSectionView(
                        transportStore: transportStore,
                        partyId: partyId,
                        currentUserId: currentUserId,
                        currentUserRole: currentUserRole
                    )
                }
                
                Spacer()
            }
            .navigationTitle("Transport")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        onDismiss?()
                    }
                }
            }
        }
        .onAppear {
            Task {
                await flightsStore.loadFlights(partyId: partyId)
                await transportStore.loadTransportations(partyId: partyId)
            }
        }
    }
}

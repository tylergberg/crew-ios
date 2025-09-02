import SwiftUI
import Supabase

@MainActor
final class SleepingArrangementsStore: ObservableObject {
    @Published var rooms: [LodgingRoom] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase: SupabaseClient
    
    init(supabase: SupabaseClient) { self.supabase = supabase }
    
    func load(partyId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            // Find lodging id for party
            struct LodgingRow: Decodable { let id: UUID }
            let lodgings: [LodgingRow] = try await supabase
                .from("lodgings")
                .select("id")
                .eq("party_id", value: partyId)
                .order("created_at", ascending: true)
                .limit(1)
                .execute()
                .value
            guard let lodging = lodgings.first else { rooms = []; return }
            
            // Load rooms
            struct RoomRow: Decodable { let id: UUID; let name: String }
            let roomRows: [RoomRow] = try await supabase
                .from("rooms")
                .select("id,name")
                .eq("lodging_id", value: lodging.id)
                .order("order_index", ascending: true)
                .execute()
                .value
            
            var built: [LodgingRoom] = []
            for room in roomRows {
                // Load beds for room
                struct BedRow: Decodable { let id: UUID; let type: String }
                let bedRows: [BedRow] = try await supabase
                    .from("beds")
                    .select("id,type")
                    .eq("room_id", value: room.id)
                    .order("order_index", ascending: true)
                    .execute()
                    .value
                
                // Load assignments per bed
                var beds: [LodgingBed] = []
                for bed in bedRows {
                    struct AssignRow: Decodable { let display_name: String? }
                    let assigns: [AssignRow] = try await supabase
                        .from("bed_assignments")
                        .select("display_name")
                        .eq("bed_id", value: bed.id)
                        .execute()
                        .value
                    let name = assigns.first?.display_name
                    beds.append(LodgingBed(id: bed.id, type: bed.type, assignedTo: name))
                }
                built.append(LodgingRoom(id: room.id, name: room.name, beds: beds))
            }
            rooms = built
        } catch {
            errorMessage = error.localizedDescription
            rooms = []
        }
    }
}

struct SleepingArrangementsView: View {
    let partyId: UUID
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = SleepingArrangementsStore(supabase: SupabaseManager.shared.client)
    
    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
            } else {
                RoomListView(rooms: store.rooms)
            }
        }
        .navigationTitle("Sleeping Arrangements")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") { dismiss() }
            }
        }
        .task { await store.load(partyId: partyId) }
    }
}



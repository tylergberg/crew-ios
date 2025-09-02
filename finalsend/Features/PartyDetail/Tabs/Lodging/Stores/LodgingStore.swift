import Foundation
import Supabase

@MainActor
final class LodgingStore: ObservableObject {
    @Published var lodgingTitle: String = ""
    @Published var lodgingAddress: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase: SupabaseClient

    init(supabase: SupabaseClient) {
        self.supabase = supabase
    }

    func loadLodgings(partyId: UUID) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            struct LodgingRow: Decodable {
                let id: UUID
                let title: String
                let address: String
            }

            // Fetch first lodging for the party
            let lodgings: [LodgingRow] = try await supabase
                .from("lodgings")
                .select("id,title,address")
                .eq("party_id", value: partyId)
                .order("created_at", ascending: true)
                .limit(1)
                .execute()
                .value

            guard let lodging = lodgings.first else {
                self.lodgingTitle = "No lodging yet"
                self.lodgingAddress = ""
                return
            }

            self.lodgingTitle = lodging.title
            self.lodgingAddress = lodging.address

            // Only summary on Lodging tab; rooms/beds load in SleepingArrangementsView
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}



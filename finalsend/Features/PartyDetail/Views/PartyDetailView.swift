import SwiftUI
import Supabase

struct PartyDetailView: View {
    let partyId: String

    @State private var party: PartyData? = nil
    @State private var isLoading: Bool = false
    @State private var errorMessage: String? = nil
    @State private var selectedTab: PartyDetailTab = .overview

    var body: some View {
        ZStack {
            Color(red: 0.607, green: 0.784, blue: 0.933).ignoresSafeArea()

            VStack(spacing: 0) {
                if isLoading {
                    ProgressView("Loading party details...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let party = party {
                    ZStack(alignment: .bottomLeading) {
                        if let url = URL(string: party.coverImageUrl) {
                            AsyncImage(url: url) { image in
                                image.resizable()
                                     .scaledToFill()
                            } placeholder: {
                                Color.gray.opacity(0.3)
                            }
                            .frame(height: 220)
                            .clipped()
                            .cornerRadius(16)
                            .shadow(radius: 5)
                        } else {
                            Color.gray.opacity(0.3)
                                .frame(height: 220)
                                .cornerRadius(16)
                                .shadow(radius: 5)
                        }

                        Text(party.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.4))
                            .cornerRadius(10)
                            .padding()
                    }
                    .padding(.horizontal)

                    PartyTabNavigation(selectedTab: $selectedTab, visibleTabs: PartyDetailTab.allCases)
                        .padding([.horizontal, .top])

                    ScrollView {
                        switch selectedTab {
                        case .overview:
                            OverviewTabView()
                        case .crew:
                            Text("No crew information available.")
                        case .itinerary:
                            Text("No itinerary available.")
                        case .chat:
                            Text("Chat tab placeholder")
                        case .vendors:
                            Text("Vendors tab placeholder")
                        case .lodging:
                            Text("Lodging tab placeholder")
                        case .transport:
                            Text("Transport tab placeholder")
                        case .expenses:
                            Text("Expenses tab placeholder")
                        case .packing:
                            Text("Packing tab placeholder")
                        case .tasks:
                            Text("Tasks tab placeholder")
                        case .gallery:
                            Text("Gallery tab placeholder")
                        case .ai:
                            Text("AI tab placeholder")
                        case .games:
                            Text("Games tab placeholder")
                        case .merch:
                            Text("Merch tab placeholder")
                        case .map:
                            Text("Map tab placeholder")
                        }
                    }
                    .padding()
                } else {
                    EmptyView()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadParty()
        }
    }

    private func loadParty() async {
        isLoading = true
        errorMessage = nil
        party = nil

        struct CityData: Decodable {
            let timezone: String?
        }

        struct PartyRow: Decodable {
            let name: String
            let description: String?
            let cover_image_url: String
            let start_date: String?
            let end_date: String?
            let location: String?
            let party_type: String?
            let party_vibe_tags: [String]?
            let cities: CityData?
        }

        do {
            let client = SupabaseClient(
                supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
                supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
            )

            let partyRow: PartyRow = try await client
                .from("parties")
                .select("id, name, description, cover_image_url, start_date, end_date, location, party_type, party_vibe_tags, cities(timezone)")
                .eq("id", value: partyId)
                .single()
                .execute()
                .value

            party = PartyData(
                name: partyRow.name,
                description: partyRow.description,
                coverImageUrl: partyRow.cover_image_url,
                startDate: partyRow.start_date,
                endDate: partyRow.end_date,
                location: partyRow.location,
                partyType: partyRow.party_type,
                vibeTags: partyRow.party_vibe_tags,
                timezone: partyRow.cities?.timezone
            )
        } catch {
            errorMessage = "Failed to load party details: \(error.localizedDescription)"
        }

        isLoading = false
    }
}

struct PartyData {
    let name: String
    let description: String?
    let coverImageUrl: String
    let startDate: String?
    let endDate: String?
    let location: String?
    let partyType: String?
    let vibeTags: [String]?
    let timezone: String?
}

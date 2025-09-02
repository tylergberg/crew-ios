//
//  PartyOverviewTab.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-07-30.
//

import SwiftUI
import Supabase

struct OverviewTabView: View {
    @EnvironmentObject var partyManager: PartyManager
    @State private var isLoading = true
    @State private var showingEditLocation = false
    @State private var showingEditDates = false
    @State private var showingEditDescription = false
    @State private var showingEditPartyType = false
    @State private var showingEditPartyVibe = false

    var body: some View {
        Group {
            if partyManager.partyId.isEmpty || isLoading {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Loading party info...")
                    Text("partyId: \(partyManager.partyId)")
                    Text("isLoading: \(isLoading.description)")
                    Text("partyManager.isLoaded: \(partyManager.isLoaded.description)")
                }
                .padding(.top, 100)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Location Card
                        OverviewLocationCard(
                            location: formatLocation(),
                            onEdit: { showingEditLocation = true }
                        )
                        .padding(.horizontal)
                        .onAppear {
                            print("=== CARD DATA DEBUG ===")
                            print("Location card - location: '\(formatLocation())'")
                            print("PartyManager location: '\(partyManager.location)'")
                            print("PartyManager description: '\(partyManager.description)'")
                            print("PartyManager partyType: '\(partyManager.partyType)'")
                            print("PartyManager vibeTags: \(partyManager.vibeTags)")
                            print("PartyManager startDate: \(partyManager.startDate)")
                            print("PartyManager endDate: \(partyManager.endDate)")
                        }

                        // Dates Card
                        OverviewDatesCard(
                            startDate: partyManager.startDate,
                            endDate: partyManager.endDate,
                            onEdit: { showingEditDates = true }
                        )
                        .padding(.horizontal)

                        // Party Type Card
                        OverviewPartyTypeCard(
                            partyType: formatPartyType(partyManager.partyType),
                            onEdit: { showingEditPartyType = true }
                        )
                        .padding(.horizontal)

                        // Party Vibe Card
                        OverviewPartyVibeCard(
                            vibeTags: partyManager.vibeTags,
                            onEdit: { showingEditPartyVibe = true }
                        )
                        .padding(.horizontal)

                        // Description Card
                        if !partyManager.description.isEmpty || partyManager.isOrganizerOrAdmin {
                            OverviewDescriptionCard(
                                description: partyManager.description.isEmpty ? "No description added yet" : partyManager.description,
                                onEdit: { showingEditDescription = true }
                            )
                            .padding(.horizontal)
                        }

                        // Timezone Card
                        if !partyManager.timezone.isEmpty {
                            OverviewTimezoneCard(timezone: partyManager.timezone)
                                .padding(.horizontal)
                        }

                        // Party Size Card
                        OverviewPartySizeCard(confirmedCount: partyManager.partySize)
                            .padding(.horizontal)

                        // Add to Home Screen Card
                        AddToHomeScreenCard()
                            .padding(.horizontal)

                        // Feedback Card
                        FeedbackCard(onOpenFeedback: { print("Feedback tapped") })
                            .padding(.horizontal)

                        // Social Links Card
                        SocialLinksCard()
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: 600)
                    .padding(.vertical)
                }
                .background(Color(red: 0.98, green: 0.95, blue: 0.91).ignoresSafeArea())
            }
        }
        .onAppear {
            print("OverviewTabView appeared")
            Task {
                print("onAppear: isLoading =", isLoading)
                print("onAppear: partyId =", partyManager.partyId)
                print("onAppear: partyManager.isLoaded =", partyManager.isLoaded)
                
                // Always fetch detailed party data for the overview tab
                if isLoading {
                    print("Fetching party overview…")
                    if partyManager.partyId.isEmpty {
                        print("Warning: partyId is still empty. Skipping fetch.")
                        await MainActor.run { isLoading = false }
                    } else {
                        await fetchPartyOverview()
                        print("fetchPartyOverview finished")
                    }
                }
            }
        }
    }

    private func formatLocation() -> String {
        if !partyManager.location.isEmpty && partyManager.location != "Location TBD" {
            return partyManager.location
        }
        return "No location set"
    }

    private func formatPartyType(_ partyType: String) -> String {
        if partyType.isEmpty {
            return "No party type set"
        }
        switch partyType.lowercased() {
        case "bachelor":
            return "Bachelor Party"
        case "bachelorette":
            return "Bachelorette Party"
        default:
            return partyType
        }
    }

    func fetchPartyOverview() async {
        guard !partyManager.partyId.isEmpty else {
            print("Party ID is empty")
            return
        }
        let partyId = partyManager.partyId
        print("Fetching party overview for ID:", partyId)
        let client = SupabaseClient(
            supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
        )

        do {
            struct PartyData: Decodable {
                let description: String?
                let start_date: String?
                let end_date: String?
                let party_type: String?
                let party_vibe_tags: [String]?
                let city_id: String?
                let cities: CityData?

                struct CityData: Decodable {
                    let id: String?
                    let city: String?
                    let state_or_province: String?
                    let country: String?
                    let timezone: String?
                }
            }

            let response = try await client
                .from("parties")
                .select("id, name, description, start_date, end_date, cover_image_url, theme_id, party_type, party_vibe_tags, city_id, cities(id, city, state_or_province, country, timezone)")
                .eq("id", value: partyId)
                .single()
                .execute()

            let result = try JSONDecoder().decode(PartyData.self, from: response.data)

            print("=== SUPABASE FETCH RESULT ===")
            print("Description: \(result.description ?? "nil")")
            print("Start Date: \(result.start_date ?? "nil")")
            print("End Date: \(result.end_date ?? "nil")")
            print("Party Type: \(result.party_type ?? "nil")")
            print("Vibe Tags: \(result.party_vibe_tags ?? [])")
            print("City ID: \(result.city_id ?? "nil")")
            print("City: \(result.cities?.city ?? "nil")")
            print("State: \(result.cities?.state_or_province ?? "nil")")
            print("Country: \(result.cities?.country ?? "nil")")
            print("Timezone: \(result.cities?.timezone ?? "nil")")

            // Update party manager
            await MainActor.run {
                print("=== SETTING PARTY MANAGER VALUES ===")
                partyManager.description = result.description ?? ""
                print("Set description: \(partyManager.description)")
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                dateFormatter.timeZone = TimeZone(secondsFromGMT: 0) // UTC

                if let startDateString = result.start_date,
                   let parsedStartDate = dateFormatter.date(from: startDateString) {
                    partyManager.startDate = parsedStartDate
                    print("Set startDate: \(partyManager.startDate)")
                } else {
                    print("Failed to parse startDate: \(result.start_date ?? "nil")")
                }

                if let endDateString = result.end_date,
                   let parsedEndDate = dateFormatter.date(from: endDateString) {
                    partyManager.endDate = parsedEndDate
                    print("Set endDate: \(partyManager.endDate)")
                } else {
                    print("Failed to parse endDate: \(result.end_date ?? "nil")")
                }
                
                // Set cityId from the parties table if available
                if let cityId = result.city_id {
                    partyManager.cityId = UUID(uuidString: cityId)
                    print("Set cityId: \(partyManager.cityId?.uuidString ?? "nil")")
                } else {
                    partyManager.cityId = nil
                    print("No cityId available")
                }
                
                // Create a proper display name for the location
                if let city = result.cities?.city {
                    if let state = result.cities?.state_or_province {
                        partyManager.location = "\(city), \(state)"
                    } else {
                        partyManager.location = city
                    }
                    print("Set location: \(partyManager.location)")
                } else {
                    partyManager.location = ""
                    print("No city available")
                }
                
                partyManager.timezone = result.cities?.timezone ?? "America/New_York"
                print("Set timezone: \(partyManager.timezone)")
                
                partyManager.partyType = result.party_type ?? ""
                print("Set partyType: \(partyManager.partyType)")
                
                partyManager.vibeTags = result.party_vibe_tags ?? []
                print("Set vibeTags: \(partyManager.vibeTags)")
                
                isLoading = false
                print("Done fetching. isLoading = false")
            }
        } catch {
            print("Failed to fetch overview:", error)
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Add to Home Screen Card
struct AddToHomeScreenCard: View {
    var body: some View {
        OverviewCard(
            iconName: "plus.square.on.square",
            title: "Add to Home Screen"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Get quick access to this party by adding it to your home screen!")
                    .font(.subheadline)
                    .foregroundColor(Color(red: 0.25, green: 0.11, blue: 0.09))
                
                Button(action: {
                    // TODO: Implement add to home screen functionality
                    print("Add to home screen tapped")
                }) {
                    Text("ADD TO HOME SCREEN")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.black, lineWidth: 1)
                        )
                }
            }
        }
    }
}

struct OverviewTabView_Previews: PreviewProvider {
    static var previews: some View {
        let mockManager = PartyManager()
        mockManager.description = "Mock party description"
        mockManager.startDate = Date()
        mockManager.endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        mockManager.location = "New York City"
        mockManager.timezone = "America/New_York"
        return OverviewTabView()
            .environmentObject(mockManager)
    }
}

// MARK: - Card Style Modifier
struct OverviewCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 0.98, green: 0.95, blue: 0.91))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(Color.black, lineWidth: 2)
            )
    }
}

extension View {
    func overviewCardStyle() -> some View {
        self.modifier(OverviewCardStyle())
    }
}

// MARK: - Card Content Helpers
struct OverviewCard<Content: View>: View {
    let iconName: String
    let title: String
    let editable: Bool
    let onEdit: (() -> Void)?
    let content: Content

    init(
        iconName: String,
        title: String,
        editable: Bool = false,
        onEdit: (() -> Void)? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.iconName = iconName
        self.title = title
        self.editable = editable
        self.onEdit = onEdit
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .center) {
                Image(systemName: iconName)
                    .foregroundColor(Color(red: 0.98, green: 0.45, blue: 0.25))
                    .frame(width: 20, height: 20)
                Text(title)
                    .font(.custom("Georgia", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                Spacer()
                if editable, let onEdit = onEdit {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundColor(Color(red: 0.98, green: 0.45, blue: 0.25))
                    }
                    .buttonStyle(.borderless)
                }
            }
            content
        }
        .overviewCardStyle()
    }
}

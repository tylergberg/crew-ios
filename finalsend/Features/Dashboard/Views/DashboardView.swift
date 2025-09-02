import Foundation
import SwiftUI
import Supabase

enum PartyTab: String, CaseIterable {
    case upcoming = "Party Plans"
    case inprogress = "Party Time"
    case past = "Party Past"
}

struct PartyCity: Decodable {
    let city: String?
}

struct DashboardView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var partyManager: PartyManager
    @State private var parties: [Party] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedTab: PartyTab = .upcoming
    @State private var userName: String? = nil
    @State private var showingCreateParty = false
    @State private var profileImageURL: String? = nil
    @State private var showingProfile = false
    @State private var currentUserId: String? = nil

var body: some View {
    buildDashboardBody()
}

@ViewBuilder
private func buildDashboardBody() -> some View {
    NavigationView {
        ZStack {
            Color(red: 0.607, green: 0.784, blue: 0.933).ignoresSafeArea()
            dashboardContent()
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingCreateParty) {
            CreatePartyView()
                .onDisappear {
                    fetchParties()
                }
        }
        .sheet(isPresented: $showingProfile) {
            if let userId = currentUserId {
                ProfileView(userId: userId)
            }
        }
    }
    .onAppear {
        fetchParties()
    }
}

private func dashboardContent() -> some View {
    VStack(spacing: 0) {
        DashboardHeaderView(
            selectedTab: $selectedTab,
            profileImageURL: headerURL,
            onNewPartyTapped: { showingCreateParty = true },
            onProfileTapped: { showingProfile = true },
            onLogoutTapped: {
                print("Logout tapped – implement navigation and session clearing")
            },
            userName: displayName
        )
        .padding(.top)

        partyListSection()
    }
}

private func partyListSection() -> some View {
    ZStack {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                Spacer().frame(height: 12)
                if isLoading {
                    ProgressView("Loading parties...")
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                        .padding()
                } else if filteredParties().isEmpty {
                    emptyPartyState()
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredParties(), id: \.id) { party in
                            NavigationLink(
                                destination: {
                                    PartyDetailView(partyId: party.id.uuidString)
                                        .environmentObject(partyManager)
                                        .onAppear {
                                            partyManager.load(from: PartyModel(fromParty: party), role: nil)
                                        }
                                },
                                label: {
                                    PartyCardView(party: party)
                                        .padding(.horizontal)
                                }
                            )
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(.bottom)
        }
    }
}

private func emptyPartyState() -> some View {
    VStack(spacing: 12) {
        switch selectedTab {
        case .upcoming:
            Image("partyplans")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .padding(.bottom, 8)

            Text("No upcoming parties")
                .font(.headline)
                .foregroundColor(Color(red: 15/255, green: 23/255, blue: 42/255))

            Text("Time to plan the perfect party!")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button(action: {
                showingCreateParty = true
            }) {
                Text("CREATE A PARTY")
                    .fontWeight(.bold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.yellow)
                    .foregroundColor(.black)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.black, lineWidth: 1)
                    )
            }
            .padding(.top, 12)

        case .inprogress:
            Image("partytime")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .padding(.bottom, 8)

            Text("Party loading...")
                .font(.headline)
                .foregroundColor(Color(red: 15/255, green: 23/255, blue: 42/255))

            Text("Your trip will appear here once the party officially kicks off.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

        case .past:
            Image("partypast")
                .resizable()
                .scaledToFit()
                .frame(width: 160, height: 160)
                .padding(.bottom, 8)

            Text("Memories live here")
                .font(.headline)
                .foregroundColor(Color(red: 15/255, green: 23/255, blue: 42/255))

            Text("Once the party’s over, your recaps will show up here.")
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
    }
    .padding(.top, 32)
}

    func fetchParties() {
        isLoading = true
        errorMessage = nil

        let client = SupabaseClient(
            supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
            supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
        )

        Task {
            do {
                // Swift 6: Always use async session getter, handle errors
                do {
                    let session = try await client.auth.session
                    let user = session.user
                    self.currentUserId = user.id.uuidString

                    // Fetch user profile
                    struct Profile: Decodable {
                        let full_name: String?
                        let avatar_url: String?
                    }

                    do {
                        let profile: Profile = try await client
                            .from("profiles")
                            .select("full_name, avatar_url")
                            .eq("id", value: user.id.uuidString)
                            .single()
                            .execute()
                            .value

                        self.userName = profile.full_name
                        self.profileImageURL = profile.avatar_url
                    } catch {
                        print("Failed to fetch user profile:", error.localizedDescription)
                    }

                    // Step 1: Get party_ids from party_member_profiles view
                    struct PartyMemberProfile: Decodable {
                        let party_id: UUID
                    }
                    let memberships: [PartyMemberProfile] = try await client
                        .from("party_member_profiles")
                        .select("party_id")
                        .eq("user_id", value: user.id.uuidString)
                        .execute()
                        .value

                    let partyIds = memberships.map { $0.party_id }

                    guard !partyIds.isEmpty else {
                        self.parties = []
                        self.isLoading = false
                        return
                    }

                    // Step 2: Fetch party info for those IDs
                    let fetchedParties: [Party] = try await client
                        .from("parties")
                        .select("id, name, start_date, end_date, cover_image_url")
                        .in("id", values: partyIds.map { $0.uuidString })
                        .execute()
                        .value

                    self.parties = fetchedParties
                    self.isLoading = false
                } catch {
                    DispatchQueue.main.async {
                        self.errorMessage = "Session error: \(error.localizedDescription)"
                        self.isLoading = false
                    }
                }
            }
        }
    }

    func filteredParties() -> [Party] {
        print("Tab:", selectedTab)
        print("Parties:", parties.map { "\($0.name): \($0.startDate ?? "nil") to \($0.endDate ?? "nil")" })

        // For testing: temporarily bypass filtering to confirm parties appear
        // let filteredParties = parties
        // return filteredParties

        let now = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        return parties.filter { party in
            guard let start = party.startDate.flatMap({ formatter.date(from: $0) }),
                  let end = party.endDate.flatMap({ formatter.date(from: $0) }) else {
                return false
            }

            switch selectedTab {
            case .upcoming:
                return start > now
            case .inprogress:
                return start <= now && end >= now
            case .past:
                return end < now
            }
        }
        .sorted { lhs, rhs in
            let lhsStart = lhs.startDate.flatMap { formatter.date(from: $0) }
            let rhsStart = rhs.startDate.flatMap { formatter.date(from: $0) }
            let lhsEnd = lhs.endDate.flatMap { formatter.date(from: $0) }
            let rhsEnd = rhs.endDate.flatMap { formatter.date(from: $0) }

            switch selectedTab {
            case .upcoming:
                return (lhsStart ?? .distantFuture) < (rhsStart ?? .distantFuture)
            case .inprogress:
                return (lhsEnd ?? .distantFuture) < (rhsEnd ?? .distantFuture)
            case .past:
                return (lhsEnd ?? .distantPast) > (rhsEnd ?? .distantPast)
            }
        }
    }

    func daysAwayString(for party: Party) -> String {
        let formatter = ISO8601DateFormatter()
        guard let start = party.startDate.flatMap({ formatter.date(from: $0) }) else { return "" }
        let days = Calendar.current.dateComponents([.day], from: Date(), to: start).day ?? 0
        return "\(days) days away"
    }
    // MARK: - Computed Properties
    private var headerURL: URL? {
        if let urlString = profileImageURL {
            return URL(string: urlString)
        }
        return nil
    }

    private var displayName: String {
        userName ?? "Guest"
    }
}

struct Party: Identifiable, Decodable {
    let id: UUID
    let name: String
    let startDate: String?
    let endDate: String?
    let city: PartyCity?
    let coverImageURL: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case startDate = "start_date"
        case endDate = "end_date"
        case coverImageURL = "cover_image_url"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.startDate = try container.decodeIfPresent(String.self, forKey: .startDate)
        self.endDate = try container.decodeIfPresent(String.self, forKey: .endDate)
        self.coverImageURL = try container.decodeIfPresent(String.self, forKey: .coverImageURL)
        self.city = nil // City data will be fetched separately when needed
    }
}

struct PartyTabSelector: View {
    @Binding var selectedTab: PartyTab

    var body: some View {
        HStack(spacing: 12) {
            ForEach(PartyTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack {
                        Image(systemName: iconName(for: tab))
                            .foregroundColor(selectedTab == tab ? .black : .gray)
                            .font(.system(size: 16, weight: .bold))
                    }
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selectedTab == tab ? Color.pink.opacity(0.7) : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black, lineWidth: 1)
                    )
                }
                .frame(height: 44)
            }
        }
        .padding(.horizontal)
    }

    func iconName(for tab: PartyTab) -> String {
        switch tab {
        case .upcoming:
            return "calendar.badge.plus"
        case .inprogress:
            return "clock"
        case .past:
            return "clock.arrow.circlepath"
        }
    }
}


#Preview {
    DashboardView()
}

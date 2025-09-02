import SwiftUI
import Supabase
import AnyCodable
let client = SupabaseClient(supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo")

struct ProfileView: View {
    let userId: String
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var isSigningOut = false
    @State private var profile: ProfileResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            VStack {
                if isSigningOut {
                    ProgressView("Signing out...")
                } else if isLoading {
                    ProgressView("Loading...")
                } else if let profile = profile {
                    ScrollView {
                        VStack(spacing: 16) {
                            if let avatarURL = profile.avatar_url, let url = URL(string: avatarURL) {
                                AsyncImage(url: url) { image in
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .clipShape(Circle())
                                } placeholder: {
                                    Circle().fill(Color.gray).frame(width: 100, height: 100)
                                }
                            }

                            Text(profile.full_name ?? "No Name")
                                .font(.title)

                            if let funStat = profile.fun_stat {
                                Text("“\(funStat)”")
                                    .italic()
                                    .foregroundColor(.secondary)
                            }

                            Group {
                                ProfileRow(label: "Phone", value: profile.phone)
                                ProfileRow(label: "Email", value: profile.email)
                                ProfileRow(label: "Instagram", value: profile.instagram_handle)
                                ProfileRow(label: "LinkedIn", value: profile.linkedin_url)
                                ProfileRow(label: "Birthday", value: profile.birthday)
                                ProfileRow(label: "Address", value: profile.home_address)
                                ProfileRow(label: "Car", value: profile.has_car == true ? "Yes (\(profile.car_seat_count ?? 0) seats)" : "No")
                                ProfileRow(label: "Beverage", value: profile.beverage_preferences)
                            }
                        }
                        .padding()
                        Button(action: signOut) {
                            Text("Sign Out")
                                .foregroundColor(.red)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                        }
                    }
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .onAppear(perform: loadProfile)
        }
    }

    func loadProfile() {
        Task {
            do {
                let response: PostgrestResponse<ProfileResponse> = try await client
                    .from("profiles")
                    .select("full_name, avatar_url, phone, email, role, home_address, has_car, car_seat_count, dietary_preferences, beverage_preferences, clothing_sizes, birthday, linkedin_url, instagram_handle, fun_stat")
                    .eq("id", value: userId)
                    .single()
                    .execute()

                self.profile = response.value
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func signOut() {
        Task {
            await MainActor.run {
                isSigningOut = true
            }
            do {
                try await client.auth.signOut()
                await MainActor.run {
                    isLoggedIn = false
                }
            } catch {
                print("Sign out failed: \(error.localizedDescription)")
                await MainActor.run {
                    isSigningOut = false
                }
            }
        }
    }
}

struct ProfileRow: View {
    var label: String
    var value: String?

    var body: some View {
        if let value = value, !value.isEmpty {
            HStack {
                Text(label)
                    .fontWeight(.semibold)
                Spacer()
                Text(value)
                    .foregroundColor(.secondary)
            }
        } else {
            EmptyView()
        }
    }
}

struct ProfileResponse: Decodable {
    let full_name: String?
    let avatar_url: String?
    let phone: String?
    let email: String?
    let role: String?
    let home_address: String?
    let has_car: Bool?
    let car_seat_count: Int?
    let dietary_preferences: [String: AnyCodable]?
    let beverage_preferences: String?
    let clothing_sizes: [String: AnyCodable]?
    let birthday: String?
    let linkedin_url: String?
    let instagram_handle: String?
    let fun_stat: String?
}

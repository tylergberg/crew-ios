import SwiftUI
import Supabase
import AnyCodable

struct ProfileView: View {
    let userId: String
    @State private var isSigningOut = false
    @State private var profile: ProfileResponse?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @StateObject private var authManager = AuthManager.shared

    var body: some View {
        NavigationView {
            VStack {
                if isSigningOut {
                    ProgressView("Signing out...")
                } else if isLoading {
                    ProgressView("Loading...")
                } else if let profile = profile {
                    ScrollView {
                        VStack(spacing: 20) {
                            // Profile Header
                            VStack(spacing: 12) {
                                AsyncImage(url: URL(string: profile.avatar_url ?? "")) { image in
                                    image.resizable()
                                        .aspectRatio(contentMode: .fill)
                                } placeholder: {
                                    Circle().fill(Color.gray.opacity(0.3))
                                }
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                                
                                Text(profile.full_name ?? "No Name")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                if let email = profile.email {
                                    Text(email)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            
                            // Profile Details
                            VStack(spacing: 16) {
                                DashboardProfileRow(label: "Phone", value: profile.phone)
                                DashboardProfileRow(label: "Role", value: profile.role)
                                DashboardProfileRow(label: "Home Address", value: profile.home_address)
                                if let hasCar = profile.has_car {
                                    DashboardProfileRow(label: "Has Car", value: hasCar ? "Yes" : "No")
                                }
                                if let hasCar = profile.has_car, hasCar, let carSeatCount = profile.car_seat_count {
                                    DashboardProfileRow(label: "Car Seat Count", value: "\(carSeatCount)")
                                }
                                DashboardProfileRow(label: "Dietary Preferences", value: formatPreferences(profile.dietary_preferences))
                                DashboardProfileRow(label: "Beverage Preferences", value: profile.beverage_preferences)
                                DashboardProfileRow(label: "Clothing Sizes", value: formatPreferences(profile.clothing_sizes))
                                if let birthday = profile.birthday {
                                    DashboardProfileRow(label: "Birthday", value: birthday)
                                }
                                DashboardProfileRow(label: "LinkedIn", value: profile.linkedin_url, isLink: true)
                                DashboardProfileRow(label: "Instagram", value: formatInstagramHandle(profile.instagram_handle), isLink: true)
                                DashboardProfileRow(label: "Fun Stat", value: profile.fun_stat)
                            }
                            .padding()
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
                let client = SupabaseManager.shared.client
                let response: PostgrestResponse<ProfileResponse> = try await client
                    .from("profiles")
                    .select("id, full_name, avatar_url, phone, email, role, home_address, has_car, car_seat_count, dietary_preferences, beverage_preferences, clothing_sizes, birthday, linkedin_url, instagram_handle, fun_stat")
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
            
            // Set logout flag immediately to prevent any database queries
            authManager.isLoggingOut = true
            
            // Use AuthManager to ensure proper cleanup
            await authManager.logout()
            
            await MainActor.run {
                isSigningOut = false
            }
        }
    }
}

// Helper function to format preferences dictionary
private func formatPreferences(_ preferences: [String: AnyCodable]?) -> String? {
    guard let preferences = preferences else { return nil }
    
    var formattedParts: [String] = []
    
    for (key, value) in preferences {
        if let stringValue = value.value as? String {
            formattedParts.append("\(key): \(stringValue)")
        } else if let arrayValue = value.value as? [String] {
            if !arrayValue.isEmpty {
                formattedParts.append("\(key): \(arrayValue.joined(separator: ", "))")
            }
        }
    }
    
    return formattedParts.isEmpty ? nil : formattedParts.joined(separator: "; ")
}

// Helper function to format Instagram handle
private func formatInstagramHandle(_ handle: String?) -> String? {
    guard let handle = handle, !handle.isEmpty else { return nil }
    
    if handle.hasPrefix("http") {
        return handle
    } else if handle.hasPrefix("@") {
        return "https://instagram.com/\(String(handle.dropFirst()))"
    } else {
        return "https://instagram.com/\(handle)"
    }
}

struct DashboardProfileRow: View {
    var label: String
    var value: String?
    var isLink: Bool = false

    var body: some View {
        if let value = value, !value.isEmpty {
            HStack {
                Text(label)
                    .fontWeight(.semibold)
                Spacer()
                if isLink, let url = URL(string: value) {
                    HStack(spacing: 8) {
                        Link(value, destination: url)
                            .foregroundColor(.blue)
                        Button(action: {
                            UIApplication.shared.open(url)
                        }) {
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.blue)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    Text(value)
                        .foregroundColor(.secondary)
                }
            }
        } else {
            EmptyView()
        }
    }
}

struct ProfileResponse: Decodable {
    let id: String?
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

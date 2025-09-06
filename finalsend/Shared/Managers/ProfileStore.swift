import Foundation
import Supabase

@MainActor
class ProfileStore: ObservableObject {
    static let shared = ProfileStore()

    @Published var current: ProfileResponse?

    private let client: SupabaseClient = SupabaseManager.shared.client

    private init() {
        NotificationCenter.default.addObserver(self, selector: #selector(handleProfileUpdated(_:)), name: .profileUpdated, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(handleAvatarUpdated(_:)), name: .avatarUpdated, object: nil)
    }

    func loadCurrentUserProfile() async {
        // Don't load profile if user is logging out
        guard !AuthManager.shared.isLoggingOut else {
            print("⚠️ Skipping profile load - user is logging out")
            return
        }
        
        do {
            let session = try await client.auth.session
            let userId = session.user.id.uuidString
            try await loadProfile(userId: userId)
        } catch {
            // no-op
        }
    }

    func loadProfile(userId: String) async throws {
        // Don't load profile if user is logging out
        guard !AuthManager.shared.isLoggingOut else {
            print("⚠️ Skipping profile load - user is logging out")
            return
        }
        
        // Convert userId string to UUID for proper database comparison
        guard let userIdUUID = UUID(uuidString: userId) else {
            throw NSError(domain: "ProfileStore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid user ID format"])
        }
        
        let response: PostgrestResponse<ProfileResponse> = try await client
            .from("profiles")
            .select("id, full_name, avatar_url, phone, email, role, home_address, has_car, car_seat_count, dietary_preferences, beverage_preferences, clothing_sizes, birthday, linkedin_url, instagram_handle, fun_stat")
            .eq("id", value: userIdUUID)
            .single()
            .execute()
        self.current = response.value
    }

    func setLocalAvatarURL(_ url: String) {
        if var profile = current {
            profile = ProfileResponse(
                id: profile.id,
                full_name: profile.full_name,
                avatar_url: url,
                phone: profile.phone,
                email: profile.email,
                role: profile.role,
                home_address: profile.home_address,
                has_car: profile.has_car,
                car_seat_count: profile.car_seat_count,
                dietary_preferences: profile.dietary_preferences,
                beverage_preferences: profile.beverage_preferences,
                clothing_sizes: profile.clothing_sizes,
                birthday: profile.birthday,
                linkedin_url: profile.linkedin_url,
                instagram_handle: profile.instagram_handle,
                fun_stat: profile.fun_stat,
                onboarding_stage: profile.onboarding_stage,
                onboarding_completed: profile.onboarding_completed,
                tos_accepted_at: profile.tos_accepted_at,
                last_seen_at: profile.last_seen_at
            )
            self.current = profile
        }
    }

    @objc private func handleProfileUpdated(_ notif: Notification) {
        guard let userId = notif.userInfo?["userId"] as? String else { return }
        Task { try? await loadProfile(userId: userId) }
    }

    @objc private func handleAvatarUpdated(_ notif: Notification) {
        // AvatarURLVersioner will bump URLs; consumers bound to current will refresh on next loadProfile
        // We still try to refresh current profile quickly if this event relates to current user
        guard let userId = notif.userInfo?["userId"] as? String else { return }
        Task { try? await loadProfile(userId: userId) }
    }
}



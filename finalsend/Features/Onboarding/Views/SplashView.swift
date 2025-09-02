import SwiftUI
import Supabase

struct SplashView: View {
    @Binding var isChecking: Bool
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    var body: some View {
        ZStack {
            Color.finalSendBlue.ignoresSafeArea()

            VStack {
                Spacer()

                Image("finalsendLogo") // Add this asset to your Assets.xcassets
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .padding()

                Spacer()
            }
        }
        .onAppear {
            checkAuthStatus()
        }
    }

    func checkAuthStatus() {
        Task {
            let client = SupabaseClient(
                supabaseURL: URL(string: "https://gyjxjigtihqzepotegjy.supabase.co")!,
                supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd5anhqaWd0aWhxemVwb3RlZ2p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDIyMzEwOTgsImV4cCI6MjA1NzgwNzA5OH0.3HQ7kvYmg7rPfyF8kB8pJe3iaMJ9sYigl8KGN3Q1rYo"
            )

            do {
                try await client.auth.refreshSession()
                await MainActor.run {
                    isLoggedIn = true
                    isChecking = false
                }
            } catch {
                await MainActor.run {
                    isLoggedIn = false
                    isChecking = false
                }
            }
        }
    }
}

import Foundation
import SwiftUI
import Supabase
import Combine

struct DashboardHeaderView: View {
    @Binding var selectedTab: PartyTab
    let profileImageURL: URL?
    let onNewPartyTapped: () -> Void
    let onProfileTapped: () -> Void
    let onLogoutTapped: () -> Void
    let userName: String?
    let unreadTaskCount: Int
    let isProfileIncomplete: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
            logo
        }
        .padding(.top, 12)
        .background(Color.neutralBackground)
    }

    private var topBar: some View {
        HStack {
            Button(action: onNewPartyTapped) {
                Text("+ NEW")
                    .font(.callout.weight(.bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.brandBlue)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                    )
            }

            Spacer()



            Button(action: onProfileTapped) {
                ZStack {
                    AsyncImage(url: profileImageURL) { image in
                        image.resizable()
                    } placeholder: {
                        Circle().fill(Color.gray.opacity(0.3))
                    }
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                    .padding(6)
                    .background(Color.white)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1))
                    
                    // Notification badge (only for tasks, removed profile completion notification)
                    let totalNotifications = unreadTaskCount
                    if totalNotifications > 0 {
                        Text("\(totalNotifications)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 12, y: -12)
                    }
                }
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal, Spacing.screenH)
    }

    private var logo: some View {
        Image("crew-wordmark")
            .resizable()
            .scaledToFit()
            .frame(width: 90, height: 90) // Slightly downscaled
            .padding(.bottom, 8)
    }
}

import Foundation
import SwiftUI
import Supabase
import Combine

extension Color {
    static let finalSendBlue = Color(red: 0.607, green: 0.784, blue: 0.933)
}

struct DashboardHeaderView: View {
    @Binding var selectedTab: PartyTab
    let profileImageURL: URL?
    let onNewPartyTapped: () -> Void
    let onProfileTapped: () -> Void
    let onLogoutTapped: () -> Void
    let userName: String?

    var body: some View {
        VStack(spacing: 16) {
            topBar
            logo
            tabSelector
        }
        .padding(.top, 12)
        .background(Color.finalSendBlue)
    }

    private var topBar: some View {
        HStack {
            Button(action: onNewPartyTapped) {
                Label("NEW", systemImage: "plus")
                    .font(.system(size: 14, weight: .bold, design: .serif))
            }
            .buttonStyle(FinalSendButtonStyle(isSelected: true))

            Spacer()

            Button(action: onProfileTapped) {
                AsyncImage(url: profileImageURL) { image in
                    image.resizable()
                } placeholder: {
                    Circle().fill(Color.gray.opacity(0.3))
                }
                .frame(width: 36, height: 36)
                .clipShape(Circle())
                .padding(6)
                .background(Color.white)
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.black, lineWidth: 2))
                .shadow(color: .black, radius: 2, x: 2, y: 2)
            }
            .frame(width: 44, height: 44)
        }
        .padding(.horizontal)
    }

    private var logo: some View {
        Image("finalsendLogo")
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .padding(.bottom, 4)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
    }

    private var tabSelector: some View {
        GeometryReader { geometry in
            HStack(spacing: 12) {
                ForEach(PartyTab.allCases, id: \.self) { tab in
                    Button(action: {
                        selectedTab = tab
                    }) {
                        tabIcon(for: tab)
                            .font(.system(size: 16, weight: .bold))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FinalSendButtonStyle(isSelected: selectedTab == tab))
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
        }
        .frame(height: 60)
    }

    private func tabIcon(for tab: PartyTab) -> some View {
        let image: Image
        switch tab {
        case .upcoming:
            image = Image(systemName: "calendar")
        case .inprogress:
            image = Image(systemName: "party.popper.fill")
        case .past:
            image = Image(systemName: "clock.fill")
        }
        return image
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
    }

    private func tabLabel(for tab: PartyTab) -> String {
        switch tab {
        case .upcoming:
            return "Party Plans"
        case .inprogress:
            return "Party Time"
        case .past:
            return "Party Past"
        }
    }
}

struct FinalSendButtonStyle: ButtonStyle {
    var isSelected: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold, design: .serif))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color(red: 0.91, green: 0.76, blue: 0.86) : Color(red: 0.99, green: 0.95, blue: 0.91))
            .foregroundColor(.black)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.black, lineWidth: 2)
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(1.0), radius: 0, x: 2, y: 2)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
    }
}

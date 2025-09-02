import SwiftUI

struct CategoryTabsView: View {
    @Binding var selectedTab: PartyTab
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(PartyTab.allCases, id: \.self) { tab in
                Button(action: {
                    selectedTab = tab
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: iconName(for: tab))
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(selectedTab == tab ? .white : .secondary)
                            .frame(width: 16, height: 16)
                        
                        Text(tabLabel(for: tab))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .white : Color(hex: "#353E3E"))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedTab == tab ? Color.brandBlue : Color.white)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.horizontal, Spacing.screenH)
        .padding(.top, 8)
    }
    
    private func iconName(for tab: PartyTab) -> String {
        switch tab {
        case .upcoming:
            return "calendar"
        case .pending:
            return "clock.badge.questionmark"
        case .declined:
            return "xmark.circle.fill"
        case .inprogress:
            return "party.popper.fill"
        case .attended:
            return "checkmark.seal.fill"
        case .didntgo:
            return "figure.walk.departure"
        }
    }
    
    private func tabLabel(for tab: PartyTab) -> String {
        switch tab {
        case .upcoming:
            return "Upcoming"
        case .pending:
            return "Pending Invites"
        case .declined:
            return "Declined Invites"
        case .inprogress:
            return "Live Trips"
        case .attended:
            return "Attended Trips"
        case .didntgo:
            return "Didn't Go"
        }
    }
}

#Preview {
    CategoryTabsView(selectedTab: .constant(.upcoming))
        .background(Color(red: 0.607, green: 0.784, blue: 0.933))
}

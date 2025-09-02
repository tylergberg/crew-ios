import SwiftUI

struct OverviewPartyTypeCard: View {
    let partyType: String
    var onEdit: (() -> Void)? = nil

    var body: some View {
        OverviewCard(iconName: "tag", title: "Party Type", editable: onEdit != nil, onEdit: onEdit) {
            Text(partyType.isEmpty ? "No party type set" : partyType)
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .padding(.vertical, 4)
    }
}



import SwiftUI

struct OverviewLocationCard: View {
    let location: String
    var onEdit: (() -> Void)? = nil

    var body: some View {
        OverviewCard(iconName: "mappin.and.ellipse", title: "Location", editable: onEdit != nil, onEdit: onEdit) {
            Text(location.isEmpty ? "No location set" : location)
                .font(.subheadline)
                .foregroundColor(.black)
        }
        .padding(.vertical, 4)
    }
}



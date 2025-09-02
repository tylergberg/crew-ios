import SwiftUI

struct SocialLinksCard: View {
    var links: [String] = []

    var body: some View {
        OverviewCard(iconName: "link", title: "Social Links") {
            if links.isEmpty {
                Text("No social links added yet")
                    .font(.subheadline)
                    .foregroundColor(.black)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(links, id: \.self) { link in
                        Text(link)
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}



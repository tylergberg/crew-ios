//
//  OverviewPartySizeCard.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct OverviewPartySizeCard: View {
    let confirmedCount: Int

    var body: some View {
        OverviewCard(
            iconName: "person.3.fill",
            title: "Party Size"
        ) {
            Text("\(confirmedCount) confirmed attendees")
                .font(.subheadline)
                .foregroundColor(Color(red: 0.25, green: 0.11, blue: 0.09))
        }
    }
}

#if DEBUG
struct OverviewPartySizeCard_Previews: PreviewProvider {
    static var previews: some View {
        OverviewPartySizeCard(confirmedCount: 6)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif

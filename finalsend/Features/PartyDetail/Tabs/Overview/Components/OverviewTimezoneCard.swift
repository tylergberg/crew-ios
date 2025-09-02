//
//  OverviewTimezoneCard.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct OverviewTimezoneCard: View {
    let timezone: String

    var body: some View {
        OverviewCard(
            iconName: "clock",
            title: "Timezone"
        ) {
            Text(timezone)
                .font(.subheadline)
                .foregroundColor(Color(red: 0.25, green: 0.11, blue: 0.09))
        }
    }
}

#Preview {
    OverviewTimezoneCard(timezone: "America/New_York")
}

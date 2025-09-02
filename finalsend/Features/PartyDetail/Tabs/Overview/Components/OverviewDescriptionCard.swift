//
//  OverviewDescriptionCard.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct OverviewDescriptionCard: View {
    var description: String
    var onEdit: () -> Void

    var body: some View {
        OverviewCard(
            iconName: "text.alignleft",
            title: "Description",
            editable: true,
            onEdit: onEdit
        ) {
            Text(description)
                .font(.subheadline)
                .foregroundColor(Color(red: 0.25, green: 0.11, blue: 0.09))
                .multilineTextAlignment(.leading)
        }
    }
}

struct OverviewDescriptionCard_Previews: PreviewProvider {
    static var previews: some View {
        OverviewDescriptionCard(
            description: "This is a sample party description that shows how the card will look with content.",
            onEdit: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

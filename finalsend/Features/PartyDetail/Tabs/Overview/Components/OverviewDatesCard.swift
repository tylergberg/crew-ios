//
//  OverviewDatesCard.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import SwiftUI

struct OverviewDatesCard: View {
    let startDate: Date
    let endDate: Date
    var onEdit: () -> Void

    var body: some View {
        OverviewCard(
            iconName: "calendar",
            title: "Dates",
            editable: true,
            onEdit: onEdit
        ) {
            Text(formatDateRange())
                .font(.subheadline)
                .foregroundColor(Color(red: 0.25, green: 0.11, blue: 0.09))
        }
    }

    private func formatDateRange() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        let startString = formatter.string(from: startDate)
        
        // Check if same year
        let calendar = Calendar.current
        if calendar.component(.year, from: startDate) == calendar.component(.year, from: endDate) {
            formatter.dateFormat = "MMM d, yyyy"
            let endString = formatter.string(from: endDate)
            return "\(startString) - \(endString)"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
            let startFullString = formatter.string(from: startDate)
            let endFullString = formatter.string(from: endDate)
            return "\(startFullString) - \(endFullString)"
        }
    }
}

struct OverviewDatesCard_Previews: PreviewProvider {
    static var previews: some View {
        OverviewDatesCard(
            startDate: Date(),
            endDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
            onEdit: {}
        )
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

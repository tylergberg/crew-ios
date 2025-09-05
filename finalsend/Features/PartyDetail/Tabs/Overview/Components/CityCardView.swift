//
//  CityCardView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI

struct CityCardView: View {
    let city: CityModel
    let isSelected: Bool
    let onTap: () -> Void
    let onDetailTap: (() -> Void)?
    
    init(city: CityModel, isSelected: Bool, onTap: @escaping () -> Void, onDetailTap: (() -> Void)? = nil) {
        self.city = city
        self.isSelected = isSelected
        self.onTap = onTap
        self.onDetailTap = onDetailTap
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                // City Image
                AsyncImage(url: URL(string: city.imageUrl ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .overlay(
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundColor(.gray)
                        )
                }
                .frame(height: 120)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])
                
                // City Info
                VStack(alignment: .leading, spacing: 4) {
                    // City Name
                    Text(city.city)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.titleDark)
                        .lineLimit(1)
                    
                    // State/Country
                    Text(city.displayName)
                        .font(.subheadline)
                        .foregroundColor(.metaGrey)
                        .lineLimit(1)
                    
                    // Quick Info Tags
                    HStack(spacing: 4) {
                        if city.budgetLevel != nil {
                            Text(city.budgetLevelDisplay)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.brandBlue.opacity(0.1))
                                .foregroundColor(.brandBlue)
                                .cornerRadius(4)
                        }
                        
                        if city.partySceneHype != nil {
                            Text(city.partySceneDisplay)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.1))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                        
                        Spacer()
                        
                        // Info button for city details
                        if onDetailTap != nil {
                            Button(action: {
                                onDetailTap?()
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.caption)
                                    .foregroundColor(.metaGrey)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.brandBlue : Color.outlineBlack.opacity(0.1), lineWidth: isSelected ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
    }
}


#Preview {
    let sampleCity = CityModel(
        id: UUID(),
        city: "Las Vegas",
        stateOrProvince: "Nevada",
        country: "United States",
        region: "Southwest",
        tags: ["nightlife", "casinos", "entertainment"],
        recommendedSeasons: ["spring", "fall"],
        avgGroupSizeMin: 4,
        avgGroupSizeMax: 12,
        budgetLevel: "luxury",
        flightAccessibilityScore: 9,
        avgFlightCost: "$300-500",
        weatherReliabilityScore: 8,
        safetyLevel: "safe",
        jetLagRisk: "low",
        walkabilityScore: 6,
        partySceneHype: "insane",
        activityDensityScore: 9,
        luxuryOptionsAvailable: true,
        popularFor: ["bachelor parties", "bachelorette parties"],
        uniqueSellingPoint: "The entertainment capital of the world",
        popularEvents: "CES, Electric Daisy Carnival",
        passportRequired: false,
        imageUrl: "https://example.com/vegas.jpg",
        isActive: true,
        createdAt: Date(),
        updatedAt: Date(),
        averageHighTemperaturesByMonth: nil,
        averageLowTemperaturesByMonth: nil,
        timezone: "America/Los_Angeles",
        latitude: 36.1699,
        longitude: -115.1398
    )
    
    VStack(spacing: 16) {
        CityCardView(city: sampleCity, isSelected: false) {
            print("Tapped city")
        }
        
        CityCardView(city: sampleCity, isSelected: true) {
            print("Tapped selected city")
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}

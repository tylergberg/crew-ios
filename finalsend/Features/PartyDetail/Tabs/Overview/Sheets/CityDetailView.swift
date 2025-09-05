//
//  CityDetailView.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-01-27.
//

import SwiftUI

struct CityDetailView: View {
    let city: CityModel
    @Environment(\.dismiss) private var dismiss
    @State private var isSelected = false
    let onSelect: (CityModel) -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Hero Image
                    AsyncImage(url: URL(string: city.imageUrl ?? "")) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)
                            )
                    }
                    .frame(height: 250)
                    .clipped()
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        VStack {
                            Spacer()
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(city.city)
                                        .font(.largeTitle)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    
                                    Text(city.displayName)
                                        .font(.title3)
                                        .foregroundColor(.white.opacity(0.9))
                                }
                                Spacer()
                            }
                            .padding()
                        }
                    )
                    
                    VStack(alignment: .leading, spacing: 20) {
                        // Quick Stats
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Stats")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.titleDark)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                StatCard(
                                    title: "Budget Level",
                                    value: city.budgetLevelDisplay,
                                    icon: "dollarsign.circle.fill",
                                    color: .green
                                )
                                
                                StatCard(
                                    title: "Party Scene",
                                    value: city.partySceneDisplay,
                                    icon: "party.popper.fill",
                                    color: .orange
                                )
                                
                                StatCard(
                                    title: "Safety",
                                    value: city.safetyLevelDisplay,
                                    icon: "shield.fill",
                                    color: .blue
                                )
                                
                                if let walkability = city.walkabilityScore {
                                    StatCard(
                                        title: "Walkability",
                                        value: "\(walkability)/10",
                                        icon: "figure.walk",
                                        color: .purple
                                    )
                                }
                            }
                        }
                        
                        // Unique Selling Point
                        if let uniqueSellingPoint = city.uniqueSellingPoint {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("What Makes It Special")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.titleDark)
                                
                                Text(uniqueSellingPoint)
                                    .font(.body)
                                    .foregroundColor(.metaGrey)
                                    .lineLimit(nil)
                            }
                        }
                        
                        // Popular For
                        if let popularFor = city.popularFor, !popularFor.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popular For")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.titleDark)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 8) {
                                    ForEach(popularFor, id: \.self) { item in
                                        Text(item)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.brandBlue.opacity(0.1))
                                            .foregroundColor(.brandBlue)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        
                        // Recommended Seasons
                        if let seasons = city.recommendedSeasons, !seasons.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Best Time to Visit")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.titleDark)
                                
                                HStack(spacing: 8) {
                                    ForEach(seasons, id: \.self) { season in
                                        Text(season.capitalized)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.orange.opacity(0.1))
                                            .foregroundColor(.orange)
                                            .cornerRadius(6)
                                    }
                                }
                            }
                        }
                        
                        // Group Size Info
                        if let minSize = city.avgGroupSizeMin, let maxSize = city.avgGroupSizeMax {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Ideal Group Size")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.titleDark)
                                
                                Text("\(minSize)-\(maxSize) people")
                                    .font(.body)
                                    .foregroundColor(.metaGrey)
                            }
                        }
                        
                        // Popular Events
                        if let events = city.popularEvents {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Popular Events")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.titleDark)
                                
                                Text(events)
                                    .font(.body)
                                    .foregroundColor(.metaGrey)
                                    .lineLimit(nil)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Select") {
                        onSelect(city)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.metaGrey)
                
                Text(value)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.titleDark)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.outlineBlack.opacity(0.1), lineWidth: 1)
        )
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
        popularFor: ["bachelor parties", "bachelorette parties", "corporate events"],
        uniqueSellingPoint: "The entertainment capital of the world with world-class shows, casinos, and nightlife that never sleeps.",
        popularEvents: "CES, Electric Daisy Carnival, World Series of Poker",
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
    
    CityDetailView(city: sampleCity) { city in
        print("Selected city: \(city.city)")
    }
}

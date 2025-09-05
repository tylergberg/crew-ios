//
//  City.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-07.
//

import Foundation

struct CityModel: Codable, Identifiable, Hashable {
    let id: UUID
    let city: String
    let stateOrProvince: String?
    let country: String
    let region: String?
    let tags: [String]?
    let recommendedSeasons: [String]?
    let avgGroupSizeMin: Int?
    let avgGroupSizeMax: Int?
    let budgetLevel: String?
    let flightAccessibilityScore: Int?
    let avgFlightCost: String?
    let weatherReliabilityScore: Int?
    let safetyLevel: String?
    let jetLagRisk: String?
    let walkabilityScore: Int?
    let partySceneHype: String?
    let activityDensityScore: Int?
    let luxuryOptionsAvailable: Bool?
    let popularFor: [String]?
    let uniqueSellingPoint: String?
    let popularEvents: String?
    let passportRequired: Bool?
    let imageUrl: String?
    let isActive: Bool?
    let createdAt: Date?
    let updatedAt: Date?
    let averageHighTemperaturesByMonth: [String: Double]?
    let averageLowTemperaturesByMonth: [String: Double]?
    let timezone: String?
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case city
        case stateOrProvince = "state_or_province"
        case country
        case region
        case tags
        case recommendedSeasons = "recommended_seasons"
        case avgGroupSizeMin = "avg_group_size_min"
        case avgGroupSizeMax = "avg_group_size_max"
        case budgetLevel = "budget_level"
        case flightAccessibilityScore = "flight_accessibility_score"
        case avgFlightCost = "avg_flight_cost"
        case weatherReliabilityScore = "weather_reliability_score"
        case safetyLevel = "safety_level"
        case jetLagRisk = "jet_lag_risk"
        case walkabilityScore = "walkability_score"
        case partySceneHype = "party_scene_hype"
        case activityDensityScore = "activity_density_score"
        case luxuryOptionsAvailable = "luxury_options_available"
        case popularFor = "popular_for"
        case uniqueSellingPoint = "unique_selling_point"
        case popularEvents = "popular_events"
        case passportRequired = "passport_required"
        case imageUrl = "image_url"
        case isActive = "is_active"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case averageHighTemperaturesByMonth = "average_high_temperatures_by_month"
        case averageLowTemperaturesByMonth = "average_low_temperatures_by_month"
        case timezone
        case latitude
        case longitude
    }
    
    var displayName: String {
        if let state = stateOrProvince {
            return "\(city), \(state)"
        }
        return city
    }
    
    var fullDisplayName: String {
        if let state = stateOrProvince {
            return "\(city), \(state), \(country)"
        }
        return "\(city), \(country)"
    }
    
    // Helper computed properties for UI display
    
    var budgetLevelDisplay: String {
        switch budgetLevel?.lowercased() {
        case "budget": return "💰 Budget"
        case "mid": return "💳 Mid-range"
        case "luxury": return "💎 Luxury"
        default: return "💳 Mid-range"
        }
    }
    
    var safetyLevelDisplay: String {
        switch safetyLevel?.lowercased() {
        case "very_safe": return "🛡️ Very Safe"
        case "safe": return "✅ Safe"
        case "moderate": return "⚠️ Moderate"
        case "caution": return "🚨 Use Caution"
        default: return "✅ Safe"
        }
    }
    
    var partySceneDisplay: String {
        switch partySceneHype?.lowercased() {
        case "insane": return "🔥 Insane"
        case "high": return "🎉 High Energy"
        case "moderate": return "🍻 Moderate"
        case "low": return "🍷 Low-key"
        default: return "🍻 Moderate"
        }
    }
}


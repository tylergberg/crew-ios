import Foundation
import Supabase

enum CitySearchError: Error, LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Data error: \(error.localizedDescription)"
        }
    }
}

protocol CitySearchServiceType {
    func fetchAllCities() async throws -> [CityModel]
    func searchCities(query: String) async throws -> [CityModel]
    func getCityById(_ cityId: UUID) async throws -> CityModel?
}

class CitySearchService: CitySearchServiceType {
    private let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseManager.shared.client) {
        self.client = client
    }
    
    /// Fetches all cities for initial display
    func fetchAllCities() async throws -> [CityModel] {
        do {
            let cities: [CityModel] = try await client
                .from("cities")
                .select("id, city, state_or_province, country, region, tags, recommended_seasons, avg_group_size_min, avg_group_size_max, budget_level, flight_accessibility_score, avg_flight_cost, weather_reliability_score, safety_level, jet_lag_risk, walkability_score, party_scene_hype, activity_density_score, luxury_options_available, popular_for, unique_selling_point, popular_events, passport_required, image_url, is_active, created_at, updated_at, average_high_temperatures_by_month, average_low_temperatures_by_month, timezone, latitude, longitude")
                .eq("is_active", value: true)
                .order("city", ascending: true)
                .limit(50)
                .execute()
                .value
            
            return cities
        } catch {
            print("❌ Error fetching all cities: \(error)")
            throw CitySearchError.networkError(error)
        }
    }
    
    /// Searches cities with autocomplete functionality
    func searchCities(query: String) async throws -> [CityModel] {
        guard !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return try await fetchAllCities()
        }
        
        let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Search across multiple fields using a more robust approach
        var cities: [CityModel] = []
        
        // First try exact city match
        do {
            let exactMatches: [CityModel] = try await client
                .from("cities")
                .select("id, city, state_or_province, country, region, tags, recommended_seasons, avg_group_size_min, avg_group_size_max, budget_level, flight_accessibility_score, avg_flight_cost, weather_reliability_score, safety_level, jet_lag_risk, walkability_score, party_scene_hype, activity_density_score, luxury_options_available, popular_for, unique_selling_point, popular_events, passport_required, image_url, is_active, created_at, updated_at, average_high_temperatures_by_month, average_low_temperatures_by_month, timezone, latitude, longitude")
                .eq("is_active", value: true)
                .ilike("city", pattern: "%\(searchQuery)%")
                .order("city", ascending: true)
                .limit(10)
                .execute()
                .value
            cities.append(contentsOf: exactMatches)
        } catch {
            print("⚠️ Exact city search failed: \(error)")
        }
        
        // Then try state/province matches if we don't have enough results
        if cities.count < 10 {
            do {
                let stateMatches: [CityModel] = try await client
                    .from("cities")
                    .select("id, city, state_or_province, country, region, tags, recommended_seasons, avg_group_size_min, avg_group_size_max, budget_level, flight_accessibility_score, avg_flight_cost, weather_reliability_score, safety_level, jet_lag_risk, walkability_score, party_scene_hype, activity_density_score, luxury_options_available, popular_for, unique_selling_point, popular_events, passport_required, image_url, is_active, created_at, updated_at, average_high_temperatures_by_month, average_low_temperatures_by_month, timezone, latitude, longitude")
                    .eq("is_active", value: true)
                    .ilike("state_or_province", pattern: "%\(searchQuery)%")
                    .order("city", ascending: true)
                    .limit(10 - cities.count)
                    .execute()
                    .value
                cities.append(contentsOf: stateMatches)
            } catch {
                print("⚠️ State search failed: \(error)")
            }
        }
        
        // Remove duplicates and limit results
        let uniqueCities = Array(Set(cities)).prefix(20)
        return Array(uniqueCities)
    }
    
    func getCityById(_ cityId: UUID) async throws -> CityModel? {
        do {
            let cities: [CityModel] = try await client
                .from("cities")
                .select("id, city, state_or_province, country, region, tags, recommended_seasons, avg_group_size_min, avg_group_size_max, budget_level, flight_accessibility_score, avg_flight_cost, weather_reliability_score, safety_level, jet_lag_risk, walkability_score, party_scene_hype, activity_density_score, luxury_options_available, popular_for, unique_selling_point, popular_events, passport_required, image_url, is_active, created_at, updated_at, average_high_temperatures_by_month, average_low_temperatures_by_month, timezone, latitude, longitude")
                .eq("id", value: cityId.uuidString)
                .execute()
                .value
            
            return cities.first
        } catch {
            print("❌ Error fetching city by ID: \(error)")
            throw CitySearchError.networkError(error)
        }
    }
    
}

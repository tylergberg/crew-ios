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
                .select("id, city, state_or_province, country, timezone")
                .order("city", ascending: true)
                .limit(20)
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
        
        do {
            let searchQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Search across multiple fields using a more robust approach
            var cities: [CityModel] = []
            
            // First try exact city match
            do {
                let exactMatches: [CityModel] = try await client
                    .from("cities")
                    .select("id, city, state_or_province, country, timezone")
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
                        .select("id, city, state_or_province, country, timezone")
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
        } catch {
            print("❌ Error searching cities: \(error)")
            throw CitySearchError.networkError(error)
        }
    }
    
    func getCityById(_ cityId: UUID) async throws -> CityModel? {
        do {
            let cities: [CityModel] = try await client
                .from("cities")
                .select("id, city, state_or_province, country, timezone")
                .eq("id", value: cityId.uuidString)
                .execute()
                .value
            
            return cities.first
        } catch {
            print("❌ Error fetching city by ID: \(error)")
            throw CitySearchError.networkError(error)
        }
    }
    
    func getPopularCities() async throws -> [CityModel] {
        do {
            // Get a mix of popular party cities
            let popularCityNames = ["Austin", "Las Vegas", "Miami", "Nashville", "Chicago", "New York", "Los Angeles", "Denver", "Phoenix", "Seattle"]
            var allCities: [CityModel] = []
            
            for cityName in popularCityNames.prefix(5) { // Limit to first 5 to avoid too many requests
                do {
                    let cities = try await searchCities(query: cityName)
                    if let firstCity = cities.first {
                        allCities.append(firstCity)
                    }
                } catch {
                    print("⚠️ Failed to load \(cityName): \(error)")
                }
            }
            
            return allCities
        } catch {
            print("❌ Error loading popular cities: \(error)")
            throw CitySearchError.networkError(error)
        }
    }
}

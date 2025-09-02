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
    let timezone: String
    let latitude: Double?
    let longitude: Double?
    
    enum CodingKeys: String, CodingKey {
        case id
        case city
        case stateOrProvince = "state_or_province"
        case country
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
}


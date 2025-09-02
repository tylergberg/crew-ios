struct PartyModel: Codable {
    let id: UUID
    let name: String
    let description_: String?
    let start_date: Date?
    let end_date: Date?
    let location: String?
    let party_type: String?
    let party_vibe_tags: [String]?
    let created_by: UUID?
    let city_id: UUID?
    let cities: CityModel? // <- Added
    let party_size: Int?
    let social_links: [String]?
}

extension PartyModel {
    init(fromParty party: Party) {
        self.id = party.id
        self.name = party.name
        self.description_ = nil
        
        // Try different date formats
        let isoFormatter = ISO8601DateFormatter()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var startDate: Date?
        var endDate: Date?
        
        if let startString = party.startDate {
            startDate = isoFormatter.date(from: startString) ?? dateFormatter.date(from: startString)
        }
        
        if let endString = party.endDate {
            endDate = isoFormatter.date(from: endString) ?? dateFormatter.date(from: endString)
        }
        
        self.start_date = startDate
        self.end_date = endDate
        self.location = party.city?.city ?? "Location TBD"
        self.party_type = nil
        self.party_vibe_tags = nil
        self.created_by = nil
        self.city_id = nil
        self.cities = nil
        self.party_size = nil
        self.social_links = nil
    }
}

struct CityModel: Codable {
    let timezone: String?
}
//
//  PartyManager.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-05.
//

import Foundation


class PartyManager: ObservableObject {
    @Published var name: String = ""
    @Published var description: String = "Welcome to the party!"
    @Published var startDate: Date = Date()
    @Published var endDate: Date = Date()
    @Published var location: String = "Las Vegas"
    @Published var timezone: String = "America/Los_Angeles"
    @Published var partyType: String = "bachelor"
    @Published var vibeTags: [String] = ["chill", "adventure"]
    @Published var partySize: Int = 8
    @Published var socialLinks: [String] = [] // New: social links
    @Published var isLoaded: Bool = true
    @Published var partyId: String = ""
    @Published var role: String? = nil

    static var mock: PartyManager {
        let manager = PartyManager()
        manager.description = "Mock party description for preview"
        manager.location = "Mockville"
        manager.startDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        manager.endDate = Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()
        manager.timezone = "America/Chicago"
        manager.partyType = "bachelorette"
        manager.vibeTags = ["fun", "wild"]
        manager.partySize = 10
        manager.socialLinks = ["https://instagram.com/mockparty"] // Mock social link
        manager.isLoaded = true
        return manager
    }
    func load(from data: PartyModel, role: String?) {
        self.name = data.name
        self.description = data.description_ ?? ""
        self.startDate = data.start_date ?? Date()
        self.endDate = data.end_date ?? Date()
        self.location = data.location ?? ""
        self.timezone = data.cities?.timezone ?? "America/New_York"
        self.partyType = data.party_type ?? ""
        self.vibeTags = data.party_vibe_tags ?? []
        self.partySize = data.party_size ?? 0
        self.socialLinks = data.social_links ?? []
        self.partyId = data.id.uuidString
        self.role = role
        self.isLoaded = true
    }
    var isOrganizerOrAdmin: Bool {
        return role == "admin" || role == "organizer"
    }
}

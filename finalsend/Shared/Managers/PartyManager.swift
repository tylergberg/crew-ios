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
    let cover_image_url: String?
    let theme_id: String?
}

extension PartyModel {
    init(fromParty party: Party) {
        print("🔍 PartyModel.init(fromParty:) - party.themeId: \(party.themeId ?? "nil")")
        
        self.id = party.id
        self.name = party.name
        self.description_ = nil
        
        // Parse date fields (stored as date, not timestamp)
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        var startDate: Date?
        var endDate: Date?
        
        if let startString = party.startDate {
            startDate = dateFormatter.date(from: startString)
        }
        
        if let endString = party.endDate {
            endDate = dateFormatter.date(from: endString)
        }
        
        self.start_date = startDate
        self.end_date = endDate
        self.location = party.city?.displayName ?? "Location TBD"
        self.party_type = party.partyType
        self.party_vibe_tags = party.vibeTags
        self.created_by = nil
        self.city_id = nil
        self.cities = nil
        self.party_size = nil
        self.social_links = nil
        self.cover_image_url = party.coverImageURL
        self.theme_id = party.themeId
        
        print("🔍 PartyModel.init(fromParty:) - self.theme_id: \(self.theme_id ?? "nil")")
    }
}

// CityModel is now defined in Shared/Models/City.swift
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
    @Published var coverImageURL: String? = nil
    @Published var isLoaded: Bool = false
    @Published var partyId: String = ""
    @Published var role: String? = nil
    @Published var cityId: UUID? = nil
    @Published var hasSelectedDates: Bool = false
    @Published var partyCreatedSuccessfully: Bool = false
    @Published var themeId: String = "default"

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
        manager.cityId = UUID()
        manager.hasSelectedDates = true
        manager.themeId = "default"
        return manager
    }
    func load(from data: PartyModel, role: String?) {
        print("🔍 PartyManager.load() - data.theme_id: \(data.theme_id ?? "nil"), role: \(role ?? "nil")")
        
        self.name = data.name
        self.description = data.description_ ?? ""
        self.startDate = data.start_date ?? Date()
        self.endDate = data.end_date ?? Date()
        self.location = data.location ?? ""
        self.timezone = data.cities?.timezone ?? "America/New_York"
        self.partyType = data.party_type ?? ""
        self.vibeTags = data.party_vibe_tags ?? []
        self.cityId = data.city_id
        self.partySize = data.party_size ?? 0
        self.socialLinks = data.social_links ?? []
        self.coverImageURL = data.cover_image_url
        self.partyId = data.id.uuidString
        self.role = role
        self.themeId = data.theme_id ?? "default"
        self.isLoaded = true
        self.hasSelectedDates = (data.start_date != nil && data.end_date != nil)
        self.partyCreatedSuccessfully = false // Reset flag when loading existing party
        
        print("🔍 PartyManager.load() - self.themeId: \(self.themeId), self.isLoaded: \(self.isLoaded), self.role: \(self.role ?? "nil")")
    }
    
    // MARK: - Theme Management
    
    var currentTheme: PartyTheme {
        let theme = PartyTheme.allThemes.first { $0.id == themeId } ?? .default
        print("🔍 PartyManager.currentTheme - themeId: \(themeId), found theme: \(theme.id)")
        return theme
    }
    
    var userRole: UserRole? {
        guard let role = role else { 
            print("🔍 PartyManager.userRole - no role set")
            return nil 
        }
        let userRole = UserRole(rawValue: role)
        print("🔍 PartyManager.userRole - role: \(role), userRole: \(userRole?.displayName ?? "nil")")
        return userRole
    }
    
    var isOrganizerOrAdmin: Bool {
        let isAdminOrOrg = role == "admin" || role == "organizer"
        print("🔍 PartyManager.isOrganizerOrAdmin - role: \(role ?? "nil"), isAdminOrOrg: \(isAdminOrOrg)")
        return isAdminOrOrg
    }
}

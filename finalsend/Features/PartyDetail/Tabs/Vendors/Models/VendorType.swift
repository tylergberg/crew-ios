import Foundation

enum VendorType: String, CaseIterable, Hashable, Codable {
    case activity
    case nightlife
    case food
    case lodging
    case transport
    case shopping
    case wellness
    case services
    case other

    static func from(types: [String]) -> VendorType {
        let lowered = types.map { $0.lowercased() }
        if lowered.contains(where: { $0.contains("activity") || $0.contains("tour") || $0.contains("experience") }) { return .activity }
        if lowered.contains(where: { $0.contains("bar") || $0.contains("club") || $0.contains("nightlife") }) { return .nightlife }
        if lowered.contains(where: { $0.contains("restaurant") || $0.contains("food") || $0.contains("dining") || $0.contains("catering") }) { return .food }
        if lowered.contains(where: { $0.contains("hotel") || $0.contains("lodging") || $0.contains("stay") || $0.contains("airbnb") }) { return .lodging }
        if lowered.contains(where: { $0.contains("transport") || $0.contains("ride") || $0.contains("bus") || $0.contains("limo") || $0.contains("boat") }) { return .transport }
        if lowered.contains(where: { $0.contains("shop") || $0.contains("merch") || $0.contains("retail") }) { return .shopping }
        if lowered.contains(where: { $0.contains("spa") || $0.contains("wellness") || $0.contains("fitness") || $0.contains("beauty") }) { return .wellness }
        if lowered.contains(where: { $0.contains("service") || $0.contains("photography") || $0.contains("planner") }) { return .services }
        return .other
    }

    var displayName: String {
        switch self {
        case .activity: return "Activities"
        case .nightlife: return "Nightlife"
        case .food: return "Food & Dining"
        case .lodging: return "Lodging"
        case .transport: return "Transport"
        case .shopping: return "Shopping"
        case .wellness: return "Wellness"
        case .services: return "Services"
        case .other: return "Other"
        }
    }
}

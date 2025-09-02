import Foundation

struct Flight: Identifiable, Codable, Hashable {
    let id: UUID
    let partyId: UUID
    let flightNumber: String
    let airline: String
    let departureAirportCode: String
    let departureAirportName: String?
    let arrivalAirportCode: String
    let arrivalAirportName: String?
    let departureTime: Date
    let arrivalTime: Date
    let direction: FlightDirection
    let notes: String?
    let createdBy: UUID
    let createdAt: Date
    let updatedAt: Date
    let departureTimezone: String?
    let arrivalTimezone: String?
    
    // Computed properties for display - Show times exactly as stored in their timezone context
    var departureDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        // Set the timezone to display the time as it was input in that timezone
        if let timezone = departureTimezone {
            formatter.timeZone = TimeZone(identifier: timezone)
        }
        return formatter.string(from: departureTime)
    }
    
    var arrivalDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, h:mm a"
        // Set the timezone to display the time as it was input in that timezone
        if let timezone = arrivalTimezone {
            formatter.timeZone = TimeZone(identifier: timezone)
        }
        return formatter.string(from: arrivalTime)
    }
    
    var departureTimezoneDisplay: String {
        guard let timezone = departureTimezone else { return "ET" }
        return getTimezoneCode(from: timezone)
    }
    
    var arrivalTimezoneDisplay: String {
        guard let timezone = arrivalTimezone else { return "ET" }
        return getTimezoneCode(from: timezone)
    }
    
    // Helper method to convert timezone identifier to short code
    private func getTimezoneCode(from timezone: String) -> String {
        switch timezone {
        case "America/New_York":
            return "EDT"
        case "America/Chicago":
            return "CDT"
        case "America/Denver":
            return "MDT"
        case "America/Los_Angeles":
            return "PDT"
        case "America/Anchorage":
            return "AKDT"
        case "Pacific/Honolulu":
            return "HST"
        case "Europe/London":
            return "BST"
        case "Europe/Paris":
            return "CEST"
        case "Asia/Tokyo":
            return "JST"
        case "Asia/Shanghai":
            return "CST"
        case "Australia/Sydney":
            return "AEST"
        case "UTC":
            return "UTC"
        default:
            return String(timezone.split(separator: "/").last?.prefix(3) ?? "TZ")
        }
    }
    
    // Route display
    var routeCode: String {
        "\(departureAirportCode) → \(arrivalAirportCode)"
    }
    
    var routeNames: String {
        let departure = departureAirportName ?? departureAirportCode
        let arrival = arrivalAirportName ?? arrivalAirportCode
        return "\(departure) → \(arrival)"
    }
    
    init(
        id: UUID = UUID(),
        partyId: UUID,
        flightNumber: String,
        airline: String,
        departureAirportCode: String,
        departureAirportName: String? = nil,
        arrivalAirportCode: String,
        arrivalAirportName: String? = nil,
        departureTime: Date,
        arrivalTime: Date,
        direction: FlightDirection,
        notes: String? = nil,
        createdBy: UUID,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        departureTimezone: String? = "America/New_York",
        arrivalTimezone: String? = "America/New_York"
    ) {
        self.id = id
        self.partyId = partyId
        self.flightNumber = flightNumber
        self.airline = airline
        self.departureAirportCode = departureAirportCode
        self.departureAirportName = departureAirportName
        self.arrivalAirportCode = arrivalAirportCode
        self.arrivalAirportName = arrivalAirportName
        self.departureTime = departureTime
        self.arrivalTime = arrivalTime
        self.direction = direction
        self.notes = notes
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.departureTimezone = departureTimezone
        self.arrivalTimezone = arrivalTimezone
    }
    
    // Custom decoding to handle timezone-aware timestamp parsing
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(UUID.self, forKey: .id)
        partyId = try container.decode(UUID.self, forKey: .partyId)
        flightNumber = try container.decode(String.self, forKey: .flightNumber)
        airline = try container.decode(String.self, forKey: .airline)
        departureAirportCode = try container.decode(String.self, forKey: .departureAirportCode)
        departureAirportName = try container.decodeIfPresent(String.self, forKey: .departureAirportName)
        arrivalAirportCode = try container.decode(String.self, forKey: .arrivalAirportCode)
        arrivalAirportName = try container.decodeIfPresent(String.self, forKey: .arrivalAirportName)
        direction = try container.decode(FlightDirection.self, forKey: .direction)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdBy = try container.decode(UUID.self, forKey: .createdBy)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
        departureTimezone = try container.decodeIfPresent(String.self, forKey: .departureTimezone) ?? "America/New_York"
        arrivalTimezone = try container.decodeIfPresent(String.self, forKey: .arrivalTimezone) ?? "America/New_York"
        
        // Parse departure time as local time in departure timezone
        let departureTimeString = try container.decode(String.self, forKey: .departureTime)
        let parsedDepartureTime = Flight.parseLocalTime(departureTimeString, timezone: departureTimezone)
        
        // Parse arrival time as local time in arrival timezone
        let arrivalTimeString = try container.decode(String.self, forKey: .arrivalTime)
        let parsedArrivalTime = Flight.parseLocalTime(arrivalTimeString, timezone: arrivalTimezone)
        
        // Now assign the parsed times
        departureTime = parsedDepartureTime
        arrivalTime = parsedArrivalTime
    }
    
    // Helper method to parse timestamp as local time in specified timezone
    private static func parseLocalTime(_ timeString: String, timezone: String?) -> Date {
        let formatter = DateFormatter()
        
        // Try different date formats that might be in the database
        let dateFormats = [
            "yyyy-MM-dd'T'HH:mm:ss",  // ISO format: 2025-09-25T08:00:00
            "yyyy-MM-dd HH:mm:ss",    // Standard format: 2025-09-25 08:00:00
            "yyyy-MM-dd'T'HH:mm:ss.SSSSSS" // ISO with microseconds: 2025-09-25T08:00:00.000000
        ]
        
        // Set the timezone to parse the time as local time in that timezone
        if let timezone = timezone {
            formatter.timeZone = TimeZone(identifier: timezone)
            print("🔍 [Flight] Parsing '\(timeString)' as local time in timezone: \(timezone)")
        } else {
            print("🔍 [Flight] Parsing '\(timeString)' as local time (no timezone specified)")
        }
        
        // Try each format until one works
        for format in dateFormats {
            formatter.dateFormat = format
            if let parsedDate = formatter.date(from: timeString) {
                print("🔍 [Flight] Successfully parsed '\(timeString)' with format '\(format)' -> \(parsedDate)")
                return parsedDate
            }
        }
        
        // If all formats fail, log the failure and return current date as fallback
        print("🔍 [Flight] Failed to parse '\(timeString)' with any format. Returning current date as fallback.")
        return Date()
    }
    
    // CodingKeys to handle snake_case from database
    enum CodingKeys: String, CodingKey {
        case id, partyId = "party_id", flightNumber = "flight_number", airline
        case departureAirportCode = "departure_airport_code"
        case departureAirportName = "departure_airport_name"
        case arrivalAirportCode = "arrival_airport_code"
        case arrivalAirportName = "arrival_airport_name"
        case departureTime = "departure_time", arrivalTime = "arrival_time"
        case direction, notes, createdBy = "created_by"
        case createdAt = "created_at", updatedAt = "updated_at"
        case departureTimezone = "departure_timezone", arrivalTimezone = "arrival_timezone"
    }
}

enum FlightDirection: String, Codable, CaseIterable {
    case arrival = "arrival"
    case departure = "departure"
    
    var displayName: String {
        switch self {
        case .arrival:
            return "Going to"
        case .departure:
            return "Leaving"
        }
    }
    
    var sectionTitle: String {
        switch self {
        case .arrival:
            return "Going to Austin, Texas"
        case .departure:
            return "Leaving Austin, Texas"
        }
    }
}

// Common timezone options
struct TimezoneOption: Identifiable, Hashable {
    let id = UUID()
    let value: String
    let displayName: String
    
    static let commonTimezones: [TimezoneOption] = [
        TimezoneOption(value: "America/New_York", displayName: "Eastern Time (ET)"),
        TimezoneOption(value: "America/Chicago", displayName: "Central Time (CT)"),
        TimezoneOption(value: "America/Denver", displayName: "Mountain Time (MT)"),
        TimezoneOption(value: "America/Los_Angeles", displayName: "Pacific Time (PT)"),
        TimezoneOption(value: "America/Anchorage", displayName: "Alaska Time (AKT)"),
        TimezoneOption(value: "Pacific/Honolulu", displayName: "Hawaii Time (HST)"),
        TimezoneOption(value: "Europe/London", displayName: "Greenwich Mean Time (GMT)"),
        TimezoneOption(value: "Europe/Paris", displayName: "Central European Time (CET)"),
        TimezoneOption(value: "Asia/Tokyo", displayName: "Japan Standard Time (JST)"),
        TimezoneOption(value: "Asia/Shanghai", displayName: "China Standard Time (CST)"),
        TimezoneOption(value: "Australia/Sydney", displayName: "Australian Eastern Time (AET)"),
        TimezoneOption(value: "UTC", displayName: "Coordinated Universal Time (UTC)")
    ]
}

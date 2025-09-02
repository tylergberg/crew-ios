import Foundation

struct CreatePartyValidators {
    
    /// Validates that a name is at least 2 characters long (trimmed)
    static func isValidName(_ name: String) -> Bool {
        return name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    /// Validates that dates are consistent (both or neither, and end >= start)
    static func validDates(start: Date?, end: Date?) -> Bool {
        if start != nil || end != nil {
            guard let start = start, let end = end else { return false }
            return end >= start
        }
        return true
    }
    
    /// Formats a date to YYYY-MM-DD string format
    static func formatDateOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
    
    /// Returns the final party type string for storage
    static func finalPartyType(type: String, custom: String) -> String {
        if type == "Other" && !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return custom.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return type
    }
    
    /// Returns a default name suggestion based on party type
    static func defaultName(for partyType: String, custom: String = "") -> String {
        switch partyType {
        case "Bachelor Party":
            return "Bachelor Party"
        case "Bachelorette Party":
            return "Bachelorette Party"
        case "Birthday Trip":
            return "Birthday Trip"
        case "Golf Trip":
            return "Golf Trip"
        case "Festival / Concert":
            return "Festival / Concert"
        case "Trip with Friends":
            return "Trip with Friends"
        case "Other":
            if !custom.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return "\(custom.trimmingCharacters(in: .whitespacesAndNewlines))"
            }
            return ""
        default:
            return ""
        }
    }
}

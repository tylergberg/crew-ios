import Foundation

struct PartyDraft {
    var name: String = ""
    var partyType: String = ""
    var customPartyType: String = ""
    var vibeTags: [String] = []
    var cityId: UUID? = nil
    var startDate: Date? = nil
    var endDate: Date? = nil
    var coverImageURL: String? = nil
    
    // Computed property to get the final party type for storage
    var finalPartyType: String {
        if partyType == "Other" && !customPartyType.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return customPartyType.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return partyType
    }
    
    // Computed property to check if dates are valid
    var hasValidDates: Bool {
        if startDate != nil || endDate != nil {
            guard let start = startDate, let end = endDate else { return false }
            return end >= start
        }
        return true
    }
    
    // Computed property to check if name is valid
    var hasValidName: Bool {
        return name.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2
    }
    
    // Computed property to check if form is valid for submission
    var isValid: Bool {
        return hasValidName && hasValidDates
    }
}

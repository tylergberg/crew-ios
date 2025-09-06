import SwiftUI

struct PartyCardView: View {
    let party: Party
    
    private var currentTheme: PartyTheme {
        return PartyTheme.allThemes.first { $0.id == party.themeId } ?? .default
    }

    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Cover Image - square using GeometryReader for responsive sizing
                GeometryReader { geometry in
                    ZStack(alignment: .topTrailing) {
                        CoverPhotoView(
                            imageURL: party.coverImageURL,
                            width: geometry.size.width,
                            height: geometry.size.width, // Make it square
                            placeholderText: "No Cover Photo"
                        )
                        
                        // Status pill (top right of cover photo)
                        if let statusText = getPartyStatusText() {
                            Text(statusText)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(getStatusBackgroundColor())
                                .cornerRadius(8)
                                .padding(12)
                        }
                    }
                                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 2)
                }
                .aspectRatio(1, contentMode: .fit) // Force square aspect ratio
                
                // Party Info
                VStack(alignment: .leading, spacing: 12) {
                    // Party Name
                    Text(party.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(currentTheme.textPrimaryColor)
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .center)
                    
                    // Party Type
                    if let partyType = party.partyType, !partyType.isEmpty {
                        HStack {
                            Image(systemName: "balloon.fill")
                                .font(.caption)
                                .foregroundColor(currentTheme.primaryAccentColor)
                                .frame(width: 16)
                            
                            Text(formatPartyType(partyType))
                                .font(.subheadline)
                                .foregroundColor(currentTheme.textSecondaryColor)
                        }
                    }
                    
                    // Location
                    HStack {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundColor(currentTheme.primaryAccentColor)
                            .frame(width: 16)
                        
                        Text(party.city?.displayName ?? "Location TBD")
                            .font(.subheadline)
                            .foregroundColor(currentTheme.textSecondaryColor)
                    }

                    // Dates
                    HStack {
                        Image(systemName: "calendar")
                            .font(.caption)
                            .foregroundColor(currentTheme.primaryAccentColor)
                            .frame(width: 16)
                        
                        if let startDate = party.startDate,
                           let endDate = party.endDate {
                            Text("\(formatDate(startDate)) – \(formatDate(endDate))")
                                .font(.subheadline)
                                .foregroundColor(currentTheme.textSecondaryColor)
                        } else {
                            Text("Dates TBD")
                                .font(.subheadline)
                                .foregroundColor(currentTheme.textSecondaryColor)
                        }
                    }
                    
                    // Attendees
                    HStack {
                        Image(systemName: "sparkle")
                            .font(.caption)
                            .foregroundColor(currentTheme.primaryAccentColor)
                            .frame(width: 16)
                        
                        if let attendeeCount = party.attendeeCount, attendeeCount > 0 {
                            Text("Crew of \(attendeeCount)")
                                .font(.subheadline)
                                .foregroundColor(currentTheme.textSecondaryColor)
                        } else {
                            Text("Crew TBD")
                                .font(.subheadline)
                                .foregroundColor(currentTheme.textSecondaryColor)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(20)
            .background(currentTheme.cardBackgroundColor)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
    }
    
    private func getPartyStatusText() -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let start = party.startDate.flatMap({ formatter.date(from: $0) }),
              let end = party.endDate.flatMap({ formatter.date(from: $0) }) else {
            return nil
        }
        
        let now = Date()
        
        // Check if party is currently live (in progress)
        if start <= now && end >= now {
            return "LIVE"
        } else if start > now {
            // Party is upcoming
            let days = Calendar.current.dateComponents([.day], from: now, to: start).day ?? 0
            if days == 0 {
                return "Today"
            } else if days == 1 {
                return "1 day"
            } else {
                return "\(days) days"
            }
        } else {
            // Party is past
            let days = Calendar.current.dateComponents([.day], from: end, to: now).day ?? 0
            if days == 0 {
                return "Yesterday"
            } else if days == 1 {
                return "1 day ago"
            } else {
                return "\(days) days ago"
            }
        }
    }
    
    private func getStatusBackgroundColor() -> Color {
        return Color(hex: "#353E3E")
    }
    
    private func formatDate(_ dateString: String) -> String {
        let inputFormatter = DateFormatter()
        inputFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = inputFormatter.date(from: dateString) else {
            return dateString
        }
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "MMM d, yyyy"
        
        return outputFormatter.string(from: date)
    }
    
    private func daysUntilParty(startDate: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let start = formatter.date(from: startDate) else {
            return nil
        }
        
        let now = Date()
        
        // Only show for upcoming parties
        guard start > now else {
            return nil
        }
        
        let days = Calendar.current.dateComponents([.day], from: now, to: start).day ?? 0
        
        if days == 0 {
            return "Today"
        } else if days == 1 {
            return "1 day"
        } else {
            return "\(days) days"
        }
    }
    
    private func partyStatusInfo(for party: Party) -> (String, Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let start = party.startDate.flatMap({ formatter.date(from: $0) }),
              let end = party.endDate.flatMap({ formatter.date(from: $0) }) else {
            return ("", false)
        }
        
        let now = Date()
        
        // Check if party is currently live (in progress)
        let isLive = start <= now && end >= now
        
        if isLive {
            return ("LIVE", true)
        } else if start > now {
            // Party is upcoming
            let days = Calendar.current.dateComponents([.day], from: now, to: start).day ?? 0
            return ("\(days) Days", false)
        } else {
            // Party is past
            return ("", false)
        }
    }
    
    private func formatPartyType(_ partyType: String) -> String {
        let lowercased = partyType.lowercased()
        if lowercased == "bachelor" {
            return "Bachelor Party"
        } else if lowercased == "bachelorette" {
            return "Bachelorette Party"
        } else {
            // Capitalize first letter of each word
            return partyType.components(separatedBy: " ")
                .map { $0.prefix(1).uppercased() + $0.dropFirst().lowercased() }
                .joined(separator: " ")
        }
    }
}

// MARK: - Attendee Avatars View
struct AttendeeAvatarsView: View {
    let attendees: [DashboardAttendee]
    
    var body: some View {
        HStack(spacing: -8) {
            ForEach(Array(sortedAttendees.prefix(5).enumerated()), id: \.element.id) { index, attendee in
                attendeeAvatarView(for: attendee, at: index)
            }
            
            if attendees.count > 5 {
                Text("+\(attendees.count - 5)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.gray)
                    .padding(.leading, 8)
                    .padding(.trailing, 4)
            }
        }
    }
    
    private var sortedAttendees: [DashboardAttendee] {
        return attendees.sorted { first, second in
            // Priority 1: Special roles (bride/groom)
            let firstHasSpecialRole = first.specialRole?.lowercased().contains("bride") == true || 
                                     first.specialRole?.lowercased().contains("groom") == true
            let secondHasSpecialRole = second.specialRole?.lowercased().contains("bride") == true || 
                                      second.specialRole?.lowercased().contains("groom") == true
            
            if firstHasSpecialRole && !secondHasSpecialRole {
                return true
            }
            if !firstHasSpecialRole && secondHasSpecialRole {
                return false
            }
            
            // If both have special roles, groom comes first
            if firstHasSpecialRole && secondHasSpecialRole {
                let firstIsGroom = first.specialRole?.lowercased().contains("groom") == true
                let secondIsGroom = second.specialRole?.lowercased().contains("groom") == true
                
                if firstIsGroom && !secondIsGroom {
                    return true
                }
                if !firstIsGroom && secondIsGroom {
                    return false
                }
            }
            
            // Priority 2: Profile pictures
            let firstHasAvatar = first.avatarUrl != nil && !first.avatarUrl!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            let secondHasAvatar = second.avatarUrl != nil && !second.avatarUrl!.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            if firstHasAvatar && !secondHasAvatar {
                return true
            }
            if !firstHasAvatar && secondHasAvatar {
                return false
            }
            
            // Priority 3: Alphabetical
            return first.fullName < second.fullName
        }
    }
    
    @ViewBuilder
    private func attendeeAvatarView(for attendee: DashboardAttendee, at index: Int) -> some View {
        Group {
            if let avatarUrl = attendee.avatarUrl, let url = URL(string: avatarUrl) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Text(attendee.initials)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(Color(hex: "#353E3E"))
                        .clipShape(Circle())
                }
                .frame(width: 28, height: 28)
                .clipShape(Circle())
            } else {
                Text(attendee.initials)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 28, height: 28)
                    .background(Color(hex: "#353E3E"))
                    .clipShape(Circle())
            }
        }
        .frame(width: 28, height: 28)
        .overlay(
            Circle()
                .strokeBorder(Color.white, lineWidth: 0.5)
        )
        .zIndex(Double(attendees.count - index))
    }
}




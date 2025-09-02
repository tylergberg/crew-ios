//
//  TimezoneUtils.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-07.
//

import Foundation

struct TimezoneUtils {
    
    /// Format a date in a specific timezone with a given format
    /// - Parameters:
    ///   - date: The date to format
    ///   - timezone: IANA timezone string (e.g., "America/New_York")
    ///   - format: Date format string
    /// - Returns: Formatted date string
    static func formatInTimezone(_ date: Date, timezone: String, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.timeZone = TimeZone(identifier: timezone)
        return formatter.string(from: date)
    }
    
    /// Convert an ISO 8601 string to a Date in the specified timezone
    /// - Parameters:
    ///   - iso: ISO 8601 formatted date string
    ///   - timezone: IANA timezone string
    /// - Returns: Date object representing the local time in the specified timezone
    static func toLocalTimezoneDate(_ iso: String, timezone: String) -> Date? {
        let isoFormatter = ISO8601DateFormatter()
        guard let utcDate = isoFormatter.date(from: iso) else { return nil }
        
        print("🕐 [TimezoneUtils] toLocalTimezoneDate debug:")
        print("  Input ISO: \(iso)")
        print("  Target timezone: \(timezone)")
        print("  UTC date: \(utcDate)")
        
        // Get the target timezone
        guard let targetTimeZone = TimeZone(identifier: timezone) else {
            print("❌ Invalid timezone: \(timezone)")
            return utcDate
        }
        
        // Create a calendar with the target timezone
        var calendar = Calendar.current
        calendar.timeZone = targetTimeZone
        
        // Get the local date components from the UTC date
        let localComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: utcDate)
        
        // Create a new date in the target timezone using those components
        // This creates a date that represents the same local time in the target timezone
        let localDate = calendar.date(from: localComponents) ?? utcDate
        
        print("  Local date: \(localDate)")
        print("  Local date components: \(calendar.dateComponents([.hour, .minute], from: localDate))")
        
        return localDate
    }
    
    /// Create a UTC datetime from party timezone date, time, and timezone
    /// - Parameters:
    ///   - date: Date selected by user (in party timezone)
    ///   - time: Time selected by user (in party timezone)
    ///   - timezone: Party's timezone (e.g., "America/Denver")
    /// - Returns: ISO 8601 formatted UTC string
    static func createUTCDateTime(date: Date, time: Date, timezone: String) -> String {
        // Extract components from user's selection (these are already in party timezone)
        let calendar = Calendar.current
        
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        
        print("🕐 [Timezone Debug] User selection (party timezone):")
        print("  Party timezone: \(timezone)")
        print("  Selected: year=\(year), month=\(month), day=\(day), hour=\(hour), minute=\(minute)")
        
        // Get the party timezone
        guard let partyTimeZone = TimeZone(identifier: timezone) else {
            print("❌ Invalid party timezone: \(timezone)")
            return ISO8601DateFormatter().string(from: Date())
        }
        
        // Create a calendar with UTC timezone for creating the base date
        var utcCalendar = Calendar.current
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
        
        // Create date components
        var dateComponents = DateComponents()
        dateComponents.year = year
        dateComponents.month = month
        dateComponents.day = day
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        
        // Create the date in UTC (this represents the local time as if it were UTC)
        guard let utcDate = utcCalendar.date(from: dateComponents) else {
            print("❌ Failed to create date from components in UTC")
            return ISO8601DateFormatter().string(from: Date())
        }
        
        // Now we need to adjust for the timezone offset
        // If the party timezone is behind UTC (like Denver), we need to add the offset
        // If the party timezone is ahead of UTC, we need to subtract the offset
        let offset = partyTimeZone.secondsFromGMT(for: utcDate)
        let finalUtcDate = utcDate.addingTimeInterval(-TimeInterval(offset))
        
        // Debug logging
        print("🕐 [Timezone Debug] Party timezone to UTC conversion:")
        print("  Party timezone: \(timezone)")
        print("  Date components: year=\(year), month=\(month), day=\(day), hour=\(hour), minute=\(minute)")
        print("  Base UTC date: \(utcDate)")
        print("  Timezone offset: \(offset / 3600) hours")
        print("  Final UTC result: \(ISO8601DateFormatter().string(from: finalUtcDate))")
        
        return ISO8601DateFormatter().string(from: finalUtcDate)
    }
    
    /// Get timezone display information
    /// - Parameter timezone: IANA timezone string
    /// - Returns: Tuple with timezone name and abbreviation
    static func getTimezoneDisplay(_ timezone: String) -> (name: String, abbr: String) {
        guard let timeZone = TimeZone(identifier: timezone) else {
            return ("Unknown", "UTC")
        }
        
        let name = timeZone.identifier.replacingOccurrences(of: "_", with: " ")
        let abbr = timeZone.abbreviation() ?? "UTC"
        
        return (name, abbr)
    }
    
    /// Get the current date in a specific timezone
    /// - Parameter timezone: IANA timezone string
    /// - Returns: Current date in the specified timezone
    static func currentDateInTimezone(_ timezone: String) -> Date {
        guard let timeZone = TimeZone(identifier: timezone) else {
            return Date()
        }
        
        let now = Date()
        let offset = timeZone.secondsFromGMT(for: now)
        return now.addingTimeInterval(TimeInterval(offset))
    }
    
    /// Format a date range for display
    /// - Parameters:
    ///   - startDate: Start date
    ///   - endDate: End date
    ///   - timezone: IANA timezone string
    /// - Returns: Formatted date range string
    static func formatDateRange(startDate: Date, endDate: Date, timezone: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(identifier: timezone)
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeZone = TimeZone(identifier: timezone)
        timeFormatter.dateFormat = "h:mm a"
        
        let startTime = timeFormatter.string(from: startDate)
        let endTime = timeFormatter.string(from: endDate)
        
        // Check if same day
        let calendar = Calendar.current
        if calendar.isDate(startDate, inSameDayAs: endDate) {
            dateFormatter.dateFormat = "MMM d, yyyy"
            let dateString = dateFormatter.string(from: startDate)
            return "\(dateString) • \(startTime) - \(endTime)"
        } else {
            dateFormatter.dateFormat = "MMM d, h:mm a"
            let startString = dateFormatter.string(from: startDate)
            let endString = dateFormatter.string(from: endDate)
            return "\(startString) - \(endString)"
        }
    }
    
    /// Get timezone abbreviation for display
    /// - Parameter timezone: IANA timezone string
    /// - Returns: Timezone abbreviation (e.g., "ET", "CT", "PT")
    static func tzAbbreviation(for timezone: String) -> String {
        guard let timeZone = TimeZone(identifier: timezone) else {
            return "UTC"
        }
        return timeZone.abbreviation() ?? "UTC"
    }
    
    /// Format a naive timestamp with timezone for display
    /// - Parameters:
    ///   - ts: Timestamp string in format "YYYY-MM-DDTHH:mm:ss"
    ///   - timezone: IANA timezone string
    /// - Returns: Formatted string like "Sep 25, 8:00 AM ET"
    static func formatNaiveTimestamp(_ ts: String, timezone: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        formatter.timeZone = TimeZone(identifier: timezone)
        
        guard let date = formatter.date(from: ts) else {
            return "Invalid date"
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "MMM d, h:mm a"
        displayFormatter.timeZone = TimeZone(identifier: timezone)
        
        let dateString = displayFormatter.string(from: date)
        let tzAbbr = tzAbbreviation(for: timezone)
        
        return "\(dateString) \(tzAbbr)"
    }
}


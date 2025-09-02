//
//  DateFormatters+Chat.swift
//  finalsend
//
//  Created by Tyler Greenberg on 2025-08-10.
//

import Foundation

struct DateFormatters {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    static let shortDateAndTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    static func chatTimestamp(_ date: Date) -> String {
        let calendar = Calendar.current
        let now = Date()
        
        if calendar.isDateInToday(date) {
            return shortTime.string(from: date)
        } else {
            return shortDateAndTime.string(from: date)
        }
    }
}


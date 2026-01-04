//
//  DateFormatter+Extensions.swift
//  playground
//
//  Centralized date formatting utilities
//

import Foundation

extension DateFormatter {
    /// Shared formatter for full date display (e.g., "Thursday, January 25, 2024")
    nonisolated static let fullDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Shared formatter for medium date display (e.g., "Jan 25, 2024")
    nonisolated static let mediumDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Shared formatter for short date display (e.g., "1/25/24")
    nonisolated static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
    }()
    
    /// Shared formatter for day name only (e.g., "Thursday")
    nonisolated static let dayName: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter
    }()
    
    /// Shared formatter for short day name (e.g., "Thu")
    /// Note: This creates a new formatter each time to respect current language
    nonisolated static var shortDayName: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        // Use system locale instead of LocalizationManager to avoid main actor isolation
        formatter.locale = Locale.current
        return formatter
    }
    
    /// Shared formatter for month and day (e.g., "January 25")
    nonisolated static let monthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter
    }()
    
    /// Shared formatter for short month and day (e.g., "Jan 25")
    nonisolated static let shortMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }()
    
    /// Shared formatter for time only (e.g., "3:45 PM")
    nonisolated static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter
    }()
    
    /// Shared formatter for weekday, month and day (e.g., "Thu, Jan 25")
    nonisolated static let weekdayMonthDay: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E, MMM d"
        return formatter
    }()
}

extension Date {
    /// Returns a localized full date string (e.g., "Thursday, January 25, 2024")
    nonisolated var fullDateString: String {
        DateFormatter.fullDate.string(from: self)
    }
    
    /// Returns a localized medium date string (e.g., "Jan 25, 2024")
    nonisolated var mediumDateString: String {
        DateFormatter.mediumDate.string(from: self)
    }
    
    /// Returns a localized short date string (e.g., "1/25/24")
    nonisolated var shortDateString: String {
        DateFormatter.shortDate.string(from: self)
    }
    
    /// Returns day name (e.g., "Thursday")
    nonisolated var dayNameString: String {
        DateFormatter.dayName.string(from: self)
    }
    
    /// Returns short day name (e.g., "Thu")
    nonisolated var shortDayNameString: String {
        DateFormatter.shortDayName.string(from: self)
    }
    
    /// Returns month and day (e.g., "January 25")
    nonisolated var monthDayString: String {
        DateFormatter.monthDay.string(from: self)
    }
    
    /// Returns short month and day (e.g., "Jan 25")
    nonisolated var shortMonthDayString: String {
        DateFormatter.shortMonthDay.string(from: self)
    }
    
    /// Returns time only (e.g., "3:45 PM")
    nonisolated var timeString: String {
        DateFormatter.timeOnly.string(from: self)
    }
    
    /// Returns weekday, month and day (e.g., "Thu, Jan 25")
    nonisolated var weekdayMonthDayString: String {
        DateFormatter.weekdayMonthDay.string(from: self)
    }
}



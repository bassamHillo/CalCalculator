//
//  Logger.swift
//  playground
//
//  Centralized logging utility with consistent format
//

import Foundation
import OSLog

/// Centralized logging utility that ensures all logs include:
/// - Class/View name
/// - Function name
/// - Log level (info, warning, error, success)
/// - Message
struct AppLogger {
    private let subsystem = Bundle.main.bundleIdentifier ?? "CalCalculator"
    private let category: String
    
    init(category: String) {
        self.category = category
    }
    
    /// Create logger for a specific class/view
    static func forClass(_ className: String) -> AppLogger {
        return AppLogger(category: className)
    }
    
    // MARK: - Logging Methods
    
    /// Log info message
    func info(_ message: String, function: String = #function, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        print("ℹ️ [\(className)] [\(function)] \(message)")
    }
    
    /// Log success message
    func success(_ message: String, function: String = #function, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        print("✅ [\(className)] [\(function)] \(message)")
    }
    
    /// Log warning message
    func warning(_ message: String, error: Error? = nil, function: String = #function, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        if let error = error {
            print("⚠️ [\(className)] [\(function)] \(message) - Error: \(error.localizedDescription)")
        } else {
            print("⚠️ [\(className)] [\(function)] \(message)")
        }
    }
    
    /// Log error message
    func error(_ message: String, error: Error? = nil, function: String = #function, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        if let error = error {
            print("❌ [\(className)] [\(function)] \(message) - Error: \(error.localizedDescription)")
        } else {
            print("❌ [\(className)] [\(function)] \(message)")
        }
    }
    
    /// Log debug message (only in debug builds)
    func debug(_ message: String, function: String = #function, file: String = #file) {
        #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        print("🔍 [\(className)] [\(function)] \(message)")
        #endif
    }
    
    /// Log data/network message
    func data(_ message: String, function: String = #function, file: String = #file) {
        let fileName = (file as NSString).lastPathComponent
        let className = fileName.replacingOccurrences(of: ".swift", with: "")
        print("📱 [\(className)] [\(function)] \(message)")
    }
}


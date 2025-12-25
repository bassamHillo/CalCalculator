//
//  ExtensionsTests.swift
//  playgroundTests
//
//  Unit tests for utility extensions
//

import XCTest
@testable import playground

final class ExtensionsTests: XCTestCase {
    
    // MARK: - Int Extensions
    
    func testFormattedCalories() {
        XCTAssertEqual(1000.formattedCalories, "1,000")
        XCTAssertEqual(500.formattedCalories, "500")
        XCTAssertEqual(1234567.formattedCalories, "1,234,567")
    }
    
    // MARK: - Double Extensions
    
    func testFormattedMacroInteger() {
        XCTAssertEqual(100.0.formattedMacro, "100")
        XCTAssertEqual(50.0.formattedMacro, "50")
        XCTAssertEqual(0.0.formattedMacro, "0")
    }
    
    func testFormattedMacroDecimal() {
        XCTAssertEqual(100.5.formattedMacro, "100.5")
        XCTAssertEqual(25.75.formattedMacro, "25.8")
        XCTAssertEqual(10.123.formattedMacro, "10.1")
    }
    
    func testFormattedPortionInteger() {
        XCTAssertEqual(100.0.formattedPortion, "100")
        XCTAssertEqual(50.0.formattedPortion, "50")
    }
    
    func testFormattedPortionDecimal() {
        XCTAssertEqual(100.5.formattedPortion, "100.5")
        XCTAssertEqual(25.75.formattedPortion, "25.8")
    }
    
    // MARK: - Date Extensions
    
    func testIsToday() {
        let today = Date()
        XCTAssertTrue(today.isToday)
        
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(yesterday.isToday)
    }
    
    func testIsYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertTrue(yesterday.isYesterday)
        
        let today = Date()
        XCTAssertFalse(today.isYesterday)
    }
    
    func testRelativeDisplayToday() {
        let today = Date()
        XCTAssertEqual(today.relativeDisplay, "Today")
    }
    
    func testRelativeDisplayYesterday() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertEqual(yesterday.relativeDisplay, "Yesterday")
    }
    
    func testRelativeDisplayOtherDate() {
        let date = Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        let expected = formatter.string(from: date)
        XCTAssertEqual(date.relativeDisplay, expected)
    }
    
    func testTimeDisplay() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let expected = formatter.string(from: date)
        XCTAssertEqual(date.timeDisplay, expected)
    }
}



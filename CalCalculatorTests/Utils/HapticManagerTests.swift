//
//  HapticManagerTests.swift
//  playgroundTests
//
//  Unit tests for HapticManager
//

import XCTest
@testable import playground

final class HapticManagerTests: XCTestCase {
    
    func testSingleton() {
        let manager1 = HapticManager.shared
        let manager2 = HapticManager.shared
        XCTAssertTrue(manager1 === manager2)
    }
    
    func testImpact() {
        let manager = HapticManager.shared
        // Just verify it doesn't crash - haptic feedback is hardware dependent
        manager.impact(.light)
        manager.impact(.medium)
        manager.impact(.heavy)
        manager.impact(.rigid)
        manager.impact(.soft)
    }
    
    func testNotification() {
        let manager = HapticManager.shared
        // Just verify it doesn't crash
        manager.notification(.success)
        manager.notification(.warning)
        manager.notification(.error)
    }
    
    func testSelection() {
        let manager = HapticManager.shared
        // Just verify it doesn't crash
        manager.selection()
    }
}



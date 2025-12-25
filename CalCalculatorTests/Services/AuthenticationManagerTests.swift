//
//  AuthenticationManagerTests.swift
//  playgroundTests
//
//  Unit tests for AuthenticationManager
//

import XCTest
@testable import playground

final class AuthenticationManagerTests: XCTestCase {
    
    var manager: AuthenticationManager!
    
    override func setUp() {
        super.setUp()
        // Use a test UserDefaults to avoid affecting real data
        UserDefaults.standard.removeObject(forKey: "auth_user_id")
        manager = AuthenticationManager.shared
    }
    
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "auth_user_id")
        super.tearDown()
    }
    
    func testSingleton() {
        let manager1 = AuthenticationManager.shared
        let manager2 = AuthenticationManager.shared
        XCTAssertTrue(manager1 === manager2)
    }
    
    func testUserIdGeneration() {
        XCTAssertNotNil(manager.userId)
        XCTAssertTrue(manager.userId?.hasPrefix("demo_user_") ?? false)
    }
    
    func testSetUserId() {
        let testId = "test_user_123"
        manager.setUserId(testId)
        XCTAssertEqual(manager.userId, testId)
    }
    
    func testIsAuthenticated() {
        manager.setUserId("test_user")
        XCTAssertTrue(manager.isAuthenticated)
        
        manager.clearCredentials()
        XCTAssertFalse(manager.isAuthenticated)
    }
    
    func testClearCredentials() {
        manager.setUserId("test_user")
        XCTAssertNotNil(manager.userId)
        
        manager.clearCredentials()
        XCTAssertNil(manager.userId)
        XCTAssertFalse(manager.isAuthenticated)
    }
    
    func testJWTTokenGeneration() {
        manager.setUserId("test_user_123")
        let token = manager.jwtToken
        
        XCTAssertNotNil(token)
        // JWT should have 3 parts separated by dots
        let parts = token?.split(separator: ".")
        XCTAssertEqual(parts?.count, 3)
    }
    
    func testJWTTokenWithoutUserId() {
        manager.clearCredentials()
        let token = manager.jwtToken
        XCTAssertNil(token)
    }
    
    func testJWTTokenFormat() {
        manager.setUserId("test_user")
        let token = manager.jwtToken
        
        XCTAssertNotNil(token)
        // Verify it's a valid JWT format (header.payload.signature)
        if let token = token {
            let parts = token.split(separator: ".")
            XCTAssertEqual(parts.count, 3)
            // Each part should be base64url encoded (no padding)
            parts.forEach { part in
                XCTAssertFalse(String(part).contains("="))
                XCTAssertFalse(String(part).contains("+"))
                XCTAssertFalse(String(part).contains("/"))
            }
        }
    }
}



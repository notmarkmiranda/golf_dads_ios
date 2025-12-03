//
//  GoogleAuthServiceTests.swift
//  GolfDadsTests
//

import XCTest
import GoogleSignIn
@testable import GolfDads

final class GoogleAuthServiceTests: XCTestCase {

    var sut: GoogleAuthService!
    let testClientID = "test-client-id.apps.googleusercontent.com"

    override func setUp() {
        super.setUp()
        sut = GoogleAuthService(clientID: testClientID)
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Init Tests

    func testInitWithClientID() {
        // When
        let service = GoogleAuthService(clientID: testClientID)

        // Then
        XCTAssertNotNil(service)
    }

    func testInitWithDefaultClientID() {
        // When
        let service = GoogleAuthService()

        // Then
        XCTAssertNotNil(service)
    }

    // MARK: - Sign In Tests

    func testSignInThrowsErrorWhenNoRootViewController() async {
        // Given
        // App is in test environment without window scene

        // When/Then
        do {
            _ = try await sut.signIn()
            XCTFail("Should have thrown error")
        } catch let error as APIError {
            if case .googleSignInFailed(let reason) = error {
                XCTAssertTrue(reason.contains("root view controller") || reason.contains("window"))
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // Note: Testing the actual Google Sign-In flow requires UI interaction
    // and is better suited for UI tests or manual testing. The integration
    // is tested via AuthenticationServiceTests.

    // MARK: - Sign Out Tests

    func testSignOutDoesNotThrow() {
        // When/Then
        XCTAssertNoThrow(sut.signOut())
    }

    func testSignOutMultipleTimesDoesNotThrow() {
        // When/Then
        XCTAssertNoThrow(sut.signOut())
        XCTAssertNoThrow(sut.signOut())
        XCTAssertNoThrow(sut.signOut())
    }
}

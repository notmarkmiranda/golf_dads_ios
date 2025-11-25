//
//  APIConfigurationTests.swift
//  GolfDadsTests
//

import XCTest
@testable import GolfDads

final class APIConfigurationTests: XCTestCase {

    func testEnvironmentIsSetCorrectly() {
        // In test builds, we should be in debug mode
        #if DEBUG
        XCTAssertEqual(APIConfiguration.environment, .development)
        #else
        XCTAssertEqual(APIConfiguration.environment, .production)
        #endif
    }

    func testBaseURLIsNotEmpty() {
        let baseURL = APIConfiguration.baseURL
        XCTAssertFalse(baseURL.isEmpty, "Base URL should not be empty")
        XCTAssertTrue(baseURL.hasPrefix("http"), "Base URL should start with http")
    }

    func testEndpointPaths() {
        // Authentication endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.signup.path, "/signup")
        XCTAssertEqual(APIConfiguration.Endpoint.login.path, "/login")
        XCTAssertEqual(APIConfiguration.Endpoint.googleSignIn.path, "/auth/google")
        XCTAssertEqual(APIConfiguration.Endpoint.currentUser.path, "/users/current")

        // User endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.users.path, "/users")
        XCTAssertEqual(APIConfiguration.Endpoint.user(id: 123).path, "/users/123")

        // Group endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.groups.path, "/groups")
        XCTAssertEqual(APIConfiguration.Endpoint.group(id: 456).path, "/groups/456")
        XCTAssertEqual(APIConfiguration.Endpoint.groupMembers(groupId: 789).path, "/groups/789/members")
        XCTAssertEqual(APIConfiguration.Endpoint.joinGroup(groupId: 111).path, "/groups/111/join")
        XCTAssertEqual(APIConfiguration.Endpoint.leaveGroup(groupId: 222).path, "/groups/222/leave")

        // Tee Time Posting endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.teeTimePostings.path, "/tee_time_postings")
        XCTAssertEqual(APIConfiguration.Endpoint.teeTimePosting(id: 333).path, "/tee_time_postings/333")
        XCTAssertEqual(APIConfiguration.Endpoint.myTeeTimePostings.path, "/tee_time_postings/my_postings")
        XCTAssertEqual(
            APIConfiguration.Endpoint.groupTeeTimePostings(groupId: 444).path,
            "/groups/444/tee_time_postings"
        )

        // Reservation endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.reservations.path, "/reservations")
        XCTAssertEqual(APIConfiguration.Endpoint.reservation(id: 555).path, "/reservations/555")
        XCTAssertEqual(APIConfiguration.Endpoint.myReservations.path, "/reservations/my_reservations")
    }

    func testFullURLConstruction() {
        let endpoint = APIConfiguration.Endpoint.login
        let fullURL = endpoint.fullURL

        XCTAssertTrue(fullURL.contains(APIConfiguration.baseURL), "Full URL should contain base URL")
        XCTAssertTrue(fullURL.hasSuffix("/login"), "Full URL should end with endpoint path")
    }

    func testTimeoutIsReasonable() {
        let timeout = APIConfiguration.timeout
        XCTAssertGreaterThan(timeout, 0, "Timeout should be positive")
        XCTAssertLessThanOrEqual(timeout, 60, "Timeout should not be excessive")
    }

    func testEnvironmentName() {
        XCTAssertEqual(APIConfiguration.Environment.development.name, "Development")
        XCTAssertEqual(APIConfiguration.Environment.production.name, "Production")
    }

    func testPrintConfigurationDoesNotCrash() {
        // This should not crash
        APIConfiguration.printConfiguration()
    }
}

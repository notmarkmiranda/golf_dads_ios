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
        XCTAssertEqual(APIConfiguration.Endpoint.signup.path, "/v1/auth/signup")
        XCTAssertEqual(APIConfiguration.Endpoint.login.path, "/v1/auth/login")
        XCTAssertEqual(APIConfiguration.Endpoint.googleSignIn.path, "/v1/auth/google")
        XCTAssertEqual(APIConfiguration.Endpoint.currentUser.path, "/v1/users/current")

        // User endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.users.path, "/v1/users")
        XCTAssertEqual(APIConfiguration.Endpoint.user(id: 123).path, "/v1/users/123")

        // Group endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.groups.path, "/v1/groups")
        XCTAssertEqual(APIConfiguration.Endpoint.group(id: 456).path, "/v1/groups/456")
        XCTAssertEqual(APIConfiguration.Endpoint.groupMembers(groupId: 789).path, "/v1/groups/789/members")
        XCTAssertEqual(APIConfiguration.Endpoint.joinGroup(groupId: 111).path, "/v1/groups/111/join")
        XCTAssertEqual(APIConfiguration.Endpoint.leaveGroup(groupId: 222).path, "/v1/groups/222/leave")

        // Tee Time Posting endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.teeTimePostings.path, "/v1/tee_time_postings")
        XCTAssertEqual(APIConfiguration.Endpoint.teeTimePosting(id: 333).path, "/v1/tee_time_postings/333")
        XCTAssertEqual(APIConfiguration.Endpoint.myTeeTimePostings.path, "/v1/tee_time_postings/my_postings")
        XCTAssertEqual(
            APIConfiguration.Endpoint.groupTeeTimePostings(groupId: 444).path,
            "/v1/groups/444/tee_time_postings"
        )

        // Reservation endpoints
        XCTAssertEqual(APIConfiguration.Endpoint.reservations.path, "/v1/reservations")
        XCTAssertEqual(APIConfiguration.Endpoint.reservation(id: 555).path, "/v1/reservations/555")
        XCTAssertEqual(APIConfiguration.Endpoint.myReservations.path, "/v1/reservations/my_reservations")
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

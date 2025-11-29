//
//  GroupInvitationTests.swift
//  GolfDadsTests
//
//  Tests for GroupInvitation model Codable conformance
//

import XCTest
@testable import GolfDads

final class GroupInvitationTests: XCTestCase {

    // MARK: - Decoding Tests

    func testDecodeGroupInvitationFromJSON() throws {
        // Given
        let json = """
        {
            "id": 1,
            "group_id": 5,
            "inviter_id": 10,
            "invitee_email": "friend@example.com",
            "status": "pending",
            "created_at": "2024-11-29T12:00:00Z",
            "updated_at": "2024-11-29T12:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let invitation = try decoder.decode(GroupInvitation.self, from: json)

        // Then
        XCTAssertEqual(invitation.id, 1)
        XCTAssertEqual(invitation.groupId, 5)
        XCTAssertEqual(invitation.inviterId, 10)
        XCTAssertEqual(invitation.inviteeEmail, "friend@example.com")
        XCTAssertEqual(invitation.status, .pending)
        XCTAssertNotNil(invitation.createdAt)
        XCTAssertNotNil(invitation.updatedAt)
    }

    func testDecodeAcceptedInvitation() throws {
        // Given
        let json = """
        {
            "id": 2,
            "group_id": 5,
            "inviter_id": 10,
            "invitee_email": "accepted@example.com",
            "status": "accepted",
            "created_at": "2024-11-29T12:00:00Z",
            "updated_at": "2024-11-29T13:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let invitation = try decoder.decode(GroupInvitation.self, from: json)

        // Then
        XCTAssertEqual(invitation.status, .accepted)
        XCTAssertTrue(invitation.isAccepted)
        XCTAssertFalse(invitation.isPending)
        XCTAssertFalse(invitation.isRejected)
    }

    func testDecodeRejectedInvitation() throws {
        // Given
        let json = """
        {
            "id": 3,
            "group_id": 5,
            "inviter_id": 10,
            "invitee_email": "rejected@example.com",
            "status": "rejected",
            "created_at": "2024-11-29T12:00:00Z",
            "updated_at": "2024-11-29T14:00:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let invitation = try decoder.decode(GroupInvitation.self, from: json)

        // Then
        XCTAssertEqual(invitation.status, .rejected)
        XCTAssertTrue(invitation.isRejected)
        XCTAssertFalse(invitation.isPending)
        XCTAssertFalse(invitation.isAccepted)
    }

    func testDecodeInvitationArray() throws {
        // Given
        let json = """
        [
            {
                "id": 1,
                "group_id": 5,
                "inviter_id": 10,
                "invitee_email": "user1@example.com",
                "status": "pending",
                "created_at": "2024-11-29T12:00:00Z",
                "updated_at": "2024-11-29T12:00:00Z"
            },
            {
                "id": 2,
                "group_id": 6,
                "inviter_id": 11,
                "invitee_email": "user2@example.com",
                "status": "accepted",
                "created_at": "2024-11-28T12:00:00Z",
                "updated_at": "2024-11-28T14:30:00Z"
            }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let invitations = try decoder.decode([GroupInvitation].self, from: json)

        // Then
        XCTAssertEqual(invitations.count, 2)
        XCTAssertEqual(invitations[0].id, 1)
        XCTAssertEqual(invitations[0].status, .pending)
        XCTAssertEqual(invitations[1].id, 2)
        XCTAssertEqual(invitations[1].status, .accepted)
    }

    // MARK: - Encoding Tests

    func testEncodeInvitationToJSON() throws {
        // Given
        let invitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .pending,
            createdAt: Date(timeIntervalSince1970: 1701259200), // 2023-11-29T12:00:00Z
            updatedAt: Date(timeIntervalSince1970: 1701259200)
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        // When
        let data = try encoder.encode(invitation)
        let json = String(data: data, encoding: .utf8)!

        // Then
        XCTAssertTrue(json.contains("\"id\":1"))
        XCTAssertTrue(json.contains("\"group_id\":5"))
        XCTAssertTrue(json.contains("\"inviter_id\":10"))
        XCTAssertTrue(json.contains("\"invitee_email\":\"test@example.com\""))
        XCTAssertTrue(json.contains("\"status\":\"pending\""))
    }

    // MARK: - Computed Properties Tests

    func testPendingStatusProperties() {
        // Given
        let invitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertTrue(invitation.isPending)
        XCTAssertFalse(invitation.isAccepted)
        XCTAssertFalse(invitation.isRejected)
    }

    func testAcceptedStatusProperties() {
        // Given
        let invitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .accepted,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertFalse(invitation.isPending)
        XCTAssertTrue(invitation.isAccepted)
        XCTAssertFalse(invitation.isRejected)
    }

    func testRejectedStatusProperties() {
        // Given
        let invitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .rejected,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertFalse(invitation.isPending)
        XCTAssertFalse(invitation.isAccepted)
        XCTAssertTrue(invitation.isRejected)
    }

    // MARK: - Equatable Tests

    func testInvitationEquality() {
        // Given
        let date = Date()
        let invitation1 = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .pending,
            createdAt: date,
            updatedAt: date
        )

        let invitation2 = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .pending,
            createdAt: date,
            updatedAt: date
        )

        let invitation3 = GroupInvitation(
            id: 2,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "different@example.com",
            status: .pending,
            createdAt: date,
            updatedAt: date
        )

        // Then
        XCTAssertEqual(invitation1, invitation2)
        XCTAssertNotEqual(invitation1, invitation3)
    }

    // MARK: - Identifiable Tests

    func testInvitationIdentifiable() {
        // Given
        let invitation = GroupInvitation(
            id: 123,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertEqual(invitation.id, 123)
    }
}

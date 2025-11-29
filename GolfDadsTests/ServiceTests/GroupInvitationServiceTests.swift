//
//  GroupInvitationServiceTests.swift
//  GolfDadsTests
//
//  Tests for GroupInvitationService
//

import XCTest
@testable import GolfDads

final class GroupInvitationServiceTests: XCTestCase {

    var sut: GroupInvitationService!
    var mockNetworkService: MockNetworkService!

    override func setUp() {
        super.setUp()
        mockNetworkService = MockNetworkService()
        sut = GroupInvitationService(networkService: mockNetworkService)
    }

    override func tearDown() {
        sut = nil
        mockNetworkService = nil
        super.tearDown()
    }

    // MARK: - Get My Invitations Tests

    func testGetMyInvitationsSuccess() async throws {
        // Given
        let mockInvitations = [
            GroupInvitation(
                id: 1,
                groupId: 5,
                inviterId: 10,
                inviteeEmail: "test1@example.com",
                status: .pending,
                createdAt: Date(),
                updatedAt: Date()
            ),
            GroupInvitation(
                id: 2,
                groupId: 6,
                inviterId: 11,
                inviteeEmail: "test2@example.com",
                status: .pending,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]

        struct Response: Encodable {
            let invitations: [GroupInvitation]
        }
        mockNetworkService.mockResponse = Response(invitations: mockInvitations)

        // When
        let invitations = try await sut.getMyInvitations()

        // Then
        XCTAssertEqual(invitations.count, 2)
        XCTAssertEqual(invitations[0].id, 1)
        XCTAssertEqual(invitations[1].id, 2)
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/v1/group_invitations")
        XCTAssertEqual(mockNetworkService.lastMethod, .get)
    }

    func testGetMyInvitationsNetworkError() async {
        // Given
        mockNetworkService.mockError = APIError.serverError(statusCode: 500, message: "Server error")

        // When/Then
        do {
            _ = try await sut.getMyInvitations()
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Get Invitation Tests

    func testGetInvitationSuccess() async throws {
        // Given
        let mockInvitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )

        struct Response: Encodable {
            let invitation: GroupInvitation
        }
        mockNetworkService.mockResponse = Response(invitation: mockInvitation)

        // When
        let invitation = try await sut.getInvitation(id: 1)

        // Then
        XCTAssertEqual(invitation.id, 1)
        XCTAssertEqual(invitation.groupId, 5)
        XCTAssertEqual(invitation.status, .pending)
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/v1/group_invitations/1")
        XCTAssertEqual(mockNetworkService.lastMethod, .get)
    }

    func testGetInvitationNotFoundError() async {
        // Given
        mockNetworkService.mockError = APIError.notFound(message: "Invitation not found")

        // When/Then
        do {
            _ = try await sut.getInvitation(id: 999)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Get Group Invitations Tests

    func testGetGroupInvitationsSuccess() async throws {
        // Given
        let mockInvitations = [
            GroupInvitation(
                id: 1,
                groupId: 5,
                inviterId: 10,
                inviteeEmail: "user1@example.com",
                status: .pending,
                createdAt: Date(),
                updatedAt: Date()
            ),
            GroupInvitation(
                id: 2,
                groupId: 5,
                inviterId: 10,
                inviteeEmail: "user2@example.com",
                status: .accepted,
                createdAt: Date(),
                updatedAt: Date()
            )
        ]

        struct Response: Encodable {
            let invitations: [GroupInvitation]
        }
        mockNetworkService.mockResponse = Response(invitations: mockInvitations)

        // When
        let invitations = try await sut.getGroupInvitations(groupId: 5)

        // Then
        XCTAssertEqual(invitations.count, 2)
        XCTAssertEqual(invitations[0].groupId, 5)
        XCTAssertEqual(invitations[1].groupId, 5)
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/v1/groups/5/invitations")
        XCTAssertEqual(mockNetworkService.lastMethod, .get)
    }

    func testGetGroupInvitationsUnauthorizedError() async {
        // Given
        mockNetworkService.mockError = APIError.unauthorized(message: "Not authorized")

        // When/Then
        do {
            _ = try await sut.getGroupInvitations(groupId: 5)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Send Invitation Tests

    func testSendInvitationSuccess() async throws {
        // Given
        let mockInvitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "newuser@example.com",
            status: .pending,
            createdAt: Date(),
            updatedAt: Date()
        )

        struct Response: Encodable {
            let invitation: GroupInvitation
        }
        mockNetworkService.mockResponse = Response(invitation: mockInvitation)

        // When
        let invitation = try await sut.sendInvitation(groupId: 5, inviteeEmail: "newuser@example.com")

        // Then
        XCTAssertEqual(invitation.id, 1)
        XCTAssertEqual(invitation.inviteeEmail, "newuser@example.com")
        XCTAssertEqual(invitation.status, .pending)
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/v1/groups/5/invitations")
        XCTAssertEqual(mockNetworkService.lastMethod, .post)
    }

    func testSendInvitationValidationError() async {
        // Given
        mockNetworkService.mockError = APIError.validationError(errors: ["email": ["is invalid"]])

        // When/Then
        do {
            _ = try await sut.sendInvitation(groupId: 5, inviteeEmail: "invalid-email")
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Accept Invitation Tests

    func testAcceptInvitationSuccess() async throws {
        // Given
        let mockInvitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .accepted,
            createdAt: Date(),
            updatedAt: Date()
        )

        struct Response: Encodable {
            let invitation: GroupInvitation
        }
        mockNetworkService.mockResponse = Response(invitation: mockInvitation)

        // When
        let invitation = try await sut.acceptInvitation(id: 1)

        // Then
        XCTAssertEqual(invitation.id, 1)
        XCTAssertEqual(invitation.status, .accepted)
        XCTAssertTrue(invitation.isAccepted)
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/v1/group_invitations/1/accept")
        XCTAssertEqual(mockNetworkService.lastMethod, .post)
    }

    func testAcceptInvitationAlreadyAcceptedError() async {
        // Given
        mockNetworkService.mockError = APIError.badRequest(message: "Invitation already accepted")

        // When/Then
        do {
            _ = try await sut.acceptInvitation(id: 1)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Reject Invitation Tests

    func testRejectInvitationSuccess() async throws {
        // Given
        let mockInvitation = GroupInvitation(
            id: 1,
            groupId: 5,
            inviterId: 10,
            inviteeEmail: "test@example.com",
            status: .rejected,
            createdAt: Date(),
            updatedAt: Date()
        )

        struct Response: Encodable {
            let invitation: GroupInvitation
        }
        mockNetworkService.mockResponse = Response(invitation: mockInvitation)

        // When
        let invitation = try await sut.rejectInvitation(id: 1)

        // Then
        XCTAssertEqual(invitation.id, 1)
        XCTAssertEqual(invitation.status, .rejected)
        XCTAssertTrue(invitation.isRejected)
        XCTAssertEqual(mockNetworkService.lastEndpoint?.path, "/v1/group_invitations/1/reject")
        XCTAssertEqual(mockNetworkService.lastMethod, .post)
    }

    func testRejectInvitationNotFoundError() async {
        // Given
        mockNetworkService.mockError = APIError.notFound(message: "Invitation not found")

        // When/Then
        do {
            _ = try await sut.rejectInvitation(id: 999)
            XCTFail("Should have thrown error")
        } catch {
            XCTAssertNotNil(error)
        }
    }
}

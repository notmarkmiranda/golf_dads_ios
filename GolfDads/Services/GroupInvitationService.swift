//
//  GroupInvitationService.swift
//  GolfDads
//
//  Service for managing group invitations via the API
//

import Foundation

/// Protocol for group invitation service operations (enables mocking for tests)
protocol GroupInvitationServiceProtocol {
    func getMyInvitations() async throws -> [GroupInvitation]
    func getInvitation(id: Int) async throws -> GroupInvitation
    func getGroupInvitations(groupId: Int) async throws -> [GroupInvitation]
    func sendInvitation(groupId: Int, inviteeEmail: String) async throws -> GroupInvitation
    func acceptInvitation(id: Int) async throws -> GroupInvitation
    func rejectInvitation(id: Int) async throws -> GroupInvitation
}

/// Service for managing group invitations
class GroupInvitationService: GroupInvitationServiceProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    // MARK: - Initialization

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// Get all invitations for the current user
    func getMyInvitations() async throws -> [GroupInvitation] {
        struct Response: Decodable {
            let invitations: [GroupInvitation]
        }

        let response: Response = try await networkService.get(
            endpoint: .groupInvitations
        )

        return response.invitations
    }

    /// Get a specific invitation by ID
    func getInvitation(id: Int) async throws -> GroupInvitation {
        struct Response: Decodable {
            let invitation: GroupInvitation
        }

        let response: Response = try await networkService.get(
            endpoint: .groupInvitation(id: id)
        )

        return response.invitation
    }

    /// Get all invitations for a specific group (owner/admin only)
    func getGroupInvitations(groupId: Int) async throws -> [GroupInvitation] {
        struct Response: Decodable {
            let invitations: [GroupInvitation]
        }

        let response: Response = try await networkService.get(
            endpoint: .groupInvitationsList(groupId: groupId)
        )

        return response.invitations
    }

    /// Send an invitation to join a group (owner/admin only)
    func sendInvitation(groupId: Int, inviteeEmail: String) async throws -> GroupInvitation {
        struct Request: Encodable {
            let groupInvitation: InvitationData

            struct InvitationData: Encodable {
                let inviteeEmail: String
            }
        }

        struct Response: Decodable {
            let invitation: GroupInvitation
        }

        let request = Request(
            groupInvitation: Request.InvitationData(
                inviteeEmail: inviteeEmail
            )
        )

        let response: Response = try await networkService.post(
            endpoint: .createGroupInvitation(groupId: groupId),
            body: request
        )

        return response.invitation
    }

    /// Accept a group invitation
    func acceptInvitation(id: Int) async throws -> GroupInvitation {
        struct Response: Decodable {
            let invitation: GroupInvitation
        }

        let response: Response = try await networkService.post(
            endpoint: .acceptInvitation(id: id),
            body: EmptyBody()
        )

        return response.invitation
    }

    /// Reject a group invitation
    func rejectInvitation(id: Int) async throws -> GroupInvitation {
        struct Response: Decodable {
            let invitation: GroupInvitation
        }

        let response: Response = try await networkService.post(
            endpoint: .rejectInvitation(id: id),
            body: EmptyBody()
        )

        return response.invitation
    }
}

// MARK: - Helper Types

/// Empty body for POST requests that don't require data
private struct EmptyBody: Encodable {}

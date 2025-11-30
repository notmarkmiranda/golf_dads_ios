//
//  GroupService.swift
//  GolfDads
//
//  Service for managing groups via the API
//

import Foundation

/// Protocol for group service operations (enables mocking for tests)
protocol GroupServiceProtocol {
    func getGroups() async throws -> [Group]
    func getGroup(id: Int) async throws -> Group
    func createGroup(name: String, description: String?) async throws -> Group
    func updateGroup(id: Int, name: String?, description: String?) async throws -> Group
    func deleteGroup(id: Int) async throws
    func regenerateInviteCode(groupId: Int) async throws -> Group
    func joinWithInviteCode(_ inviteCode: String) async throws -> Group
}

/// Service for managing groups
class GroupService: GroupServiceProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol

    // MARK: - Initialization

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// Get all groups
    func getGroups() async throws -> [Group] {
        struct Response: Decodable {
            let groups: [Group]
        }

        let response: Response = try await networkService.get(
            endpoint: .groups
        )

        return response.groups
    }

    /// Get a specific group by ID
    func getGroup(id: Int) async throws -> Group {
        struct Response: Decodable {
            let group: Group
        }

        let response: Response = try await networkService.get(
            endpoint: .group(id: id)
        )

        return response.group
    }

    /// Create a new group
    func createGroup(name: String, description: String?) async throws -> Group {
        struct Request: Encodable {
            let group: GroupData

            struct GroupData: Encodable {
                let name: String
                let description: String?
            }
        }

        struct Response: Decodable {
            let group: Group
        }

        let request = Request(
            group: Request.GroupData(
                name: name,
                description: description
            )
        )

        let response: Response = try await networkService.post(
            endpoint: .groups,
            body: request
        )

        return response.group
    }

    /// Update an existing group
    func updateGroup(id: Int, name: String?, description: String?) async throws -> Group {
        struct Request: Encodable {
            let group: GroupData

            struct GroupData: Encodable {
                let name: String?
                let description: String?
            }
        }

        struct Response: Decodable {
            let group: Group
        }

        let request = Request(
            group: Request.GroupData(
                name: name,
                description: description
            )
        )

        let response: Response = try await networkService.patch(
            endpoint: .group(id: id),
            body: request
        )

        return response.group
    }

    /// Delete a group
    func deleteGroup(id: Int) async throws {
        try await networkService.delete(
            endpoint: .group(id: id)
        )
    }

    /// Regenerate the invite code for a group (owner only)
    func regenerateInviteCode(groupId: Int) async throws -> Group {
        struct Response: Decodable {
            let group: Group
            let message: String
        }

        let response: Response = try await networkService.post(
            endpoint: .regenerateInviteCode(groupId: groupId),
            body: Optional<String>.none
        )

        return response.group
    }

    /// Join a group using an invite code
    func joinWithInviteCode(_ inviteCode: String) async throws -> Group {
        struct Request: Encodable {
            let inviteCode: String
        }

        struct Response: Decodable {
            let group: Group
            let message: String
        }

        let request = Request(inviteCode: inviteCode)

        let response: Response = try await networkService.post(
            endpoint: .joinWithInviteCode,
            body: request
        )

        return response.group
    }
}

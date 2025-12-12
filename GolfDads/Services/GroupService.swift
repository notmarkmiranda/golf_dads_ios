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
    func getGroupMembers(groupId: Int) async throws -> [GroupMember]
    func leaveGroup(id: Int) async throws
    func removeMember(groupId: Int, userId: Int) async throws
    func transferOwnership(groupId: Int, newOwnerId: Int) async throws -> Group
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

    /// Get all members of a group with their details
    func getGroupMembers(groupId: Int) async throws -> [GroupMember] {
        struct Response: Decodable {
            let members: [GroupMember]
        }

        let response: Response = try await networkService.get(
            endpoint: .groupMembers(groupId: groupId)
        )

        return response.members
    }

    /// Leave a group (members only, not owner)
    func leaveGroup(id: Int) async throws {
        struct Response: Decodable {
            let message: String
        }

        let _: Response = try await networkService.post(
            endpoint: .leaveGroup(groupId: id),
            body: Optional<String>.none
        )
    }

    /// Remove a member from a group (owner only)
    func removeMember(groupId: Int, userId: Int) async throws {
        try await networkService.delete(
            endpoint: .removeMember(groupId: groupId, userId: userId)
        )
    }

    /// Transfer group ownership to another member (owner only)
    func transferOwnership(groupId: Int, newOwnerId: Int) async throws -> Group {
        struct Request: Encodable {
            let newOwnerId: Int
        }

        struct Response: Decodable {
            let group: Group
            let message: String
        }

        let request = Request(newOwnerId: newOwnerId)

        let response: Response = try await networkService.post(
            endpoint: .transferOwnership(groupId: groupId),
            body: request
        )

        return response.group
    }
}

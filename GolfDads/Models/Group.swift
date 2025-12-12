//
//  Group.swift
//  GolfDads
//
//  Represents a golf group that users can join
//

import Foundation

struct Group: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let description: String?
    let ownerId: Int
    let inviteCode: String
    let memberNames: [String]
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Permission Helpers
extension Group {
    /// Check if the given user ID is the owner of this group
    /// - Parameter userId: The user ID to check (typically from AuthenticationManager.currentUser?.id)
    /// - Returns: True if the user is the owner, false otherwise
    func isOwner(userId: Int?) -> Bool {
        guard let userId = userId else { return false }
        return ownerId == userId
    }
}

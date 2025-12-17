//
//  GroupMember.swift
//  GolfDads
//
//  Represents a member of a golf group with their details
//

import Foundation

struct GroupMember: Codable, Identifiable, Equatable {
    let id: Int           // user_id
    let email: String
    let name: String
    let joinedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id, email, name, joinedAt
        // Note: convertFromSnakeCase decoder strategy automatically handles snake_case -> camelCase
    }
}

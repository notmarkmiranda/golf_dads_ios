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

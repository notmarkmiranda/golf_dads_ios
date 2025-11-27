//
//  TeeTimePosting.swift
//  GolfDads
//
//  Represents a tee time posting that users can browse and reserve
//

import Foundation

struct TeeTimePosting: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let userId: Int
    let groupId: Int?
    let teeTime: Date
    let courseName: String
    let availableSpots: Int
    let totalSpots: Int?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Computed Properties

    /// Returns true if this is a public posting (not restricted to a group)
    var isPublic: Bool {
        groupId == nil
    }

    /// Returns true if the tee time is in the past
    var isPast: Bool {
        teeTime < Date()
    }
}

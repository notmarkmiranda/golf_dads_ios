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

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case groupId = "group_id"
        case teeTime = "tee_time"
        case courseName = "course_name"
        case availableSpots = "available_spots"
        case totalSpots = "total_spots"
        case notes
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

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

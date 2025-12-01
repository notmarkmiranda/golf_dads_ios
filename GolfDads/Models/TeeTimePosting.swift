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
    let groupIds: [Int]
    let teeTime: Date
    let courseName: String
    let availableSpots: Int
    let totalSpots: Int?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    // MARK: - Custom Decoding

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try container.decode(Int.self, forKey: .userId)
        // Default to empty array if groupIds is missing (for backward compatibility)
        groupIds = try container.decodeIfPresent([Int].self, forKey: .groupIds) ?? []
        teeTime = try container.decode(Date.self, forKey: .teeTime)
        courseName = try container.decode(String.self, forKey: .courseName)
        availableSpots = try container.decode(Int.self, forKey: .availableSpots)
        totalSpots = try container.decodeIfPresent(Int.self, forKey: .totalSpots)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decode(Date.self, forKey: .updatedAt)
    }

    // MARK: - Manual Initializer for Tests/Previews

    init(
        id: Int,
        userId: Int,
        groupIds: [Int],
        teeTime: Date,
        courseName: String,
        availableSpots: Int,
        totalSpots: Int?,
        notes: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.groupIds = groupIds
        self.teeTime = teeTime
        self.courseName = courseName
        self.availableSpots = availableSpots
        self.totalSpots = totalSpots
        self.notes = notes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Returns true if this is a public posting (not restricted to any groups)
    var isPublic: Bool {
        groupIds.isEmpty
    }

    /// Returns true if the tee time is in the past
    var isPast: Bool {
        teeTime < Date()
    }
}

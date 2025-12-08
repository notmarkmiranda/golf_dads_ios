//
//  TeeTimePosting.swift
//  GolfDads
//
//  Represents a tee time posting that users can browse and reserve
//

import Foundation

/// Represents golf course information associated with a tee time posting
struct GolfCourseInfo: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let name: String
    let clubName: String?
    let address: String?
    let city: String?
    let state: String?
    let zipCode: String?
    let latitude: Double?
    let longitude: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, address, city, state, latitude, longitude
        case clubName = "club_name"
        case zipCode = "zip_code"
    }

    var displayLocation: String {
        var parts: [String] = []
        if let city = city { parts.append(city) }
        if let state = state { parts.append(state) }
        return parts.joined(separator: ", ")
    }
}

/// Represents a reservation on a tee time posting (only visible to posting owner)
struct ReservationInfo: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let userId: Int?  // Optional for backward compatibility with old API responses
    let userEmail: String
    let spotsReserved: Int
    let createdAt: Date
}

struct TeeTimePosting: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let userId: Int
    let groupIds: [Int]
    let teeTime: Date
    let courseName: String
    let golfCourse: GolfCourseInfo?
    let distanceMiles: Double?
    let availableSpots: Int
    let totalSpots: Int?
    let notes: String?
    let reservations: [ReservationInfo]?  // Only present if user is posting owner
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
        golfCourse = try container.decodeIfPresent(GolfCourseInfo.self, forKey: .golfCourse)
        distanceMiles = try container.decodeIfPresent(Double.self, forKey: .distanceMiles)
        availableSpots = try container.decode(Int.self, forKey: .availableSpots)
        totalSpots = try container.decodeIfPresent(Int.self, forKey: .totalSpots)
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        reservations = try container.decodeIfPresent([ReservationInfo].self, forKey: .reservations)
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
        golfCourse: GolfCourseInfo? = nil,
        distanceMiles: Double? = nil,
        availableSpots: Int,
        totalSpots: Int?,
        notes: String?,
        reservations: [ReservationInfo]? = nil,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.userId = userId
        self.groupIds = groupIds
        self.teeTime = teeTime
        self.courseName = courseName
        self.golfCourse = golfCourse
        self.distanceMiles = distanceMiles
        self.availableSpots = availableSpots
        self.totalSpots = totalSpots
        self.notes = notes
        self.reservations = reservations
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Returns the preferred display name for the course
    var displayCourseName: String {
        golfCourse?.name ?? courseName
    }

    /// Returns true if this is a public posting (not restricted to any groups)
    var isPublic: Bool {
        groupIds.isEmpty
    }

    /// Returns true if the tee time is in the past
    var isPast: Bool {
        teeTime < Date()
    }
}

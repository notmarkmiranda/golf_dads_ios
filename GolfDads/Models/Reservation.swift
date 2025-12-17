//
//  Reservation.swift
//  GolfDads
//
//  Represents a reservation made by a user for a tee time posting
//

import Foundation

struct ReservationTeeTimeInfo: Codable, Equatable, Hashable {
    let id: Int
    let userId: Int
    let courseName: String
    let teeTime: Date
    let availableSpots: Int
    let totalSpots: Int?
    let notes: String?
    let isPublic: Bool
    let isPast: Bool

    enum CodingKeys: String, CodingKey {
        case id, userId, courseName, teeTime, availableSpots, totalSpots, notes, isPublic, isPast
        // Note: convertFromSnakeCase decoder strategy automatically handles snake_case -> camelCase
    }
}

struct Reservation: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let userId: Int
    let teeTimePostingId: Int
    let spotsReserved: Int
    let createdAt: Date
    let updatedAt: Date
    let teeTimePosting: ReservationTeeTimeInfo?

    enum CodingKeys: String, CodingKey {
        case id, userId, teeTimePostingId, spotsReserved, createdAt, updatedAt, teeTimePosting
        // Note: convertFromSnakeCase decoder strategy automatically handles snake_case -> camelCase
    }
}

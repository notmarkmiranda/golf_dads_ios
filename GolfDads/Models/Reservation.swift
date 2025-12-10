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
}

struct Reservation: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let userId: Int
    let teeTimePostingId: Int
    let spotsReserved: Int
    let createdAt: Date
    let updatedAt: Date
    let teeTimePosting: ReservationTeeTimeInfo?
}

//
//  Reservation.swift
//  GolfDads
//
//  Represents a reservation made by a user for a tee time posting
//

import Foundation

struct Reservation: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let userId: Int
    let teeTimePostingId: Int
    let spotsReserved: Int
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case teeTimePostingId = "tee_time_posting_id"
        case spotsReserved = "spots_reserved"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

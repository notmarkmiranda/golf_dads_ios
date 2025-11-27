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
}

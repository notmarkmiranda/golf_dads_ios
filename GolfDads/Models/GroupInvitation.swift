//
//  GroupInvitation.swift
//  GolfDads
//
//  Represents a group invitation sent to a user
//

import Foundation

struct GroupInvitation: Codable, Identifiable, Equatable, Hashable {
    let id: Int
    let groupId: Int
    let inviterId: Int
    let inviteeEmail: String
    let status: Status
    let createdAt: Date
    let updatedAt: Date

    enum Status: String, Codable, Equatable {
        case pending
        case accepted
        case rejected
    }

    // MARK: - Computed Properties

    var isPending: Bool {
        status == .pending
    }

    var isAccepted: Bool {
        status == .accepted
    }

    var isRejected: Bool {
        status == .rejected
    }
}

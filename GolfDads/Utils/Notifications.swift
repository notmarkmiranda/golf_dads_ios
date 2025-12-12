//
//  Notifications.swift
//  GolfDads
//
//  App-wide notification names
//

import Foundation

extension Notification.Name {
    /// Posted when an unauthorized (401) error occurs, indicating token expiration
    static let unauthorizedErrorOccurred = Notification.Name("unauthorizedErrorOccurred")

    /// Posted when a group is deleted (object: group ID as Int)
    static let groupDeleted = Notification.Name("groupDeleted")

    /// Posted when a user leaves a group (object: group ID as Int)
    static let groupLeft = Notification.Name("groupLeft")

    /// Posted when a group is updated (object: updated Group)
    static let groupUpdated = Notification.Name("groupUpdated")
}

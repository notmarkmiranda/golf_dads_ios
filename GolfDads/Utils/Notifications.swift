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
}

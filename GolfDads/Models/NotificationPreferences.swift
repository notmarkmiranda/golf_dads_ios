//
//  NotificationPreferences.swift
//  GolfDads
//
//  Created by Claude Code on 12/13/24.
//

import Foundation

struct NotificationPreferences: Codable, Equatable {
    let id: Int
    let userId: Int
    var reservationsEnabled: Bool
    var groupActivityEnabled: Bool
    var remindersEnabled: Bool
    var reminder24HEnabled: Bool
    var reminder2HEnabled: Bool

    // Default preferences (all enabled)
    static var defaultPreferences: NotificationPreferences {
        NotificationPreferences(
            id: 0,
            userId: 0,
            reservationsEnabled: true,
            groupActivityEnabled: true,
            remindersEnabled: true,
            reminder24HEnabled: true,
            reminder2HEnabled: true
        )
    }
}

// Request/Response wrappers for API
struct NotificationPreferencesResponse: Codable {
    let notificationPreferences: NotificationPreferences?

    enum CodingKeys: String, CodingKey {
        case notificationPreferences
        // Note: convertFromSnakeCase decoder strategy automatically handles snake_case -> camelCase
    }
}

struct NotificationPreferencesUpdateRequest: Codable {
    let notificationPreferences: NotificationPreferencesUpdate

    enum CodingKeys: String, CodingKey {
        case notificationPreferences = "notification_preferences"
    }
}

struct NotificationPreferencesUpdate: Codable {
    var reservationsEnabled: Bool?
    var groupActivityEnabled: Bool?
    var remindersEnabled: Bool?
    var reminder24HEnabled: Bool?
    var reminder2HEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case reservationsEnabled = "reservations_enabled"
        case groupActivityEnabled = "group_activity_enabled"
        case remindersEnabled = "reminders_enabled"
        case reminder24HEnabled = "reminder_24h_enabled"
        case reminder2HEnabled = "reminder_2h_enabled"
    }
}

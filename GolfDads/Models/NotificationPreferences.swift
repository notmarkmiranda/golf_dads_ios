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
    var reminder24hEnabled: Bool
    var reminder2hEnabled: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId
        case reservationsEnabled
        case groupActivityEnabled
        case remindersEnabled
        case reminder24hEnabled = "reminder_24h_enabled"
        case reminder2hEnabled = "reminder_2h_enabled"
    }

    // Default preferences (all enabled)
    static var defaultPreferences: NotificationPreferences {
        NotificationPreferences(
            id: 0,
            userId: 0,
            reservationsEnabled: true,
            groupActivityEnabled: true,
            remindersEnabled: true,
            reminder24hEnabled: true,
            reminder2hEnabled: true
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
        case notificationPreferences
        // Note: convertFromSnakeCase decoder strategy automatically handles snake_case -> camelCase
    }
}

struct NotificationPreferencesUpdate: Codable {
    var reservationsEnabled: Bool?
    var groupActivityEnabled: Bool?
    var remindersEnabled: Bool?
    var reminder24hEnabled: Bool?
    var reminder2hEnabled: Bool?

    enum CodingKeys: String, CodingKey {
        case reservationsEnabled
        case groupActivityEnabled
        case remindersEnabled
        case reminder24hEnabled = "reminder_24h_enabled"
        case reminder2hEnabled = "reminder_2h_enabled"
    }
}

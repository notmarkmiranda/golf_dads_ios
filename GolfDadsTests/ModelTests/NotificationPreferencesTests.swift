//
//  NotificationPreferencesTests.swift
//  GolfDadsTests
//

import XCTest
@testable import GolfDads

final class NotificationPreferencesTests: XCTestCase {

    // MARK: - Decoding Tests

    func testDecodeNotificationPreferencesFromSnakeCase() throws {
        // API response format with snake_case including numbers
        let json = """
        {
            "id": 2,
            "user_id": 68,
            "reservations_enabled": true,
            "group_activity_enabled": true,
            "reminders_enabled": true,
            "reminder_24h_enabled": true,
            "reminder_2h_enabled": false
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        // Match NetworkService configuration
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let preferences = try decoder.decode(NotificationPreferences.self, from: data)

        XCTAssertEqual(preferences.id, 2)
        XCTAssertEqual(preferences.userId, 68)
        XCTAssertTrue(preferences.reservationsEnabled)
        XCTAssertTrue(preferences.groupActivityEnabled)
        XCTAssertTrue(preferences.remindersEnabled)
        XCTAssertTrue(preferences.reminder24HEnabled)
        XCTAssertFalse(preferences.reminder2HEnabled)
    }

    func testDecodeNotificationPreferencesAllDisabled() throws {
        let json = """
        {
            "id": 1,
            "user_id": 42,
            "reservations_enabled": false,
            "group_activity_enabled": false,
            "reminders_enabled": false,
            "reminder_24h_enabled": false,
            "reminder_2h_enabled": false
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        let preferences = try decoder.decode(NotificationPreferences.self, from: data)

        XCTAssertEqual(preferences.id, 1)
        XCTAssertEqual(preferences.userId, 42)
        XCTAssertFalse(preferences.reservationsEnabled)
        XCTAssertFalse(preferences.groupActivityEnabled)
        XCTAssertFalse(preferences.remindersEnabled)
        XCTAssertFalse(preferences.reminder24HEnabled)
        XCTAssertFalse(preferences.reminder2HEnabled)
    }

    // MARK: - Encoding Tests

    func testEncodeNotificationPreferencesUpdateToSnakeCase() throws {
        let update = NotificationPreferencesUpdate(
            reservationsEnabled: true,
            groupActivityEnabled: false,
            remindersEnabled: true,
            reminder24HEnabled: false,
            reminder2HEnabled: true
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let data = try encoder.encode(update)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertEqual(json["reservations_enabled"] as? Bool, true)
        XCTAssertEqual(json["group_activity_enabled"] as? Bool, false)
        XCTAssertEqual(json["reminders_enabled"] as? Bool, true)
        XCTAssertEqual(json["reminder_24h_enabled"] as? Bool, false)
        XCTAssertEqual(json["reminder_2h_enabled"] as? Bool, true)
    }

    func testEncodePartialNotificationPreferencesUpdate() throws {
        let update = NotificationPreferencesUpdate(
            reservationsEnabled: nil,
            groupActivityEnabled: true,
            remindersEnabled: nil,
            reminder24HEnabled: nil,
            reminder2HEnabled: false
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(update)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]

        XCTAssertNil(json["reservations_enabled"])
        XCTAssertEqual(json["group_activity_enabled"] as? Bool, true)
        XCTAssertNil(json["reminders_enabled"])
        XCTAssertNil(json["reminder_24h_enabled"])
        XCTAssertEqual(json["reminder_2h_enabled"] as? Bool, false)
    }

    // MARK: - Response Wrapper Tests

    func testDecodeNotificationPreferencesResponse() throws {
        let json = """
        {
            "notification_preferences": {
                "id": 5,
                "user_id": 100,
                "reservations_enabled": true,
                "group_activity_enabled": false,
                "reminders_enabled": true,
                "reminder_24h_enabled": true,
                "reminder_2h_enabled": true
            }
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(NotificationPreferencesResponse.self, from: data)

        XCTAssertNotNil(response.notificationPreferences)
        XCTAssertEqual(response.notificationPreferences?.id, 5)
        XCTAssertEqual(response.notificationPreferences?.userId, 100)
        XCTAssertTrue(response.notificationPreferences?.reservationsEnabled ?? false)
        XCTAssertFalse(response.notificationPreferences?.groupActivityEnabled ?? true)
    }

    func testDecodeNotificationPreferencesResponseNull() throws {
        let json = """
        {
            "notification_preferences": null
        }
        """

        let data = json.data(using: .utf8)!
        let decoder = JSONDecoder()

        let response = try decoder.decode(NotificationPreferencesResponse.self, from: data)

        XCTAssertNil(response.notificationPreferences)
    }

    func testEncodeNotificationPreferencesUpdateRequest() throws {
        let update = NotificationPreferencesUpdate(
            reservationsEnabled: true,
            groupActivityEnabled: nil,
            remindersEnabled: false,
            reminder24HEnabled: nil,
            reminder2HEnabled: true
        )

        let request = NotificationPreferencesUpdateRequest(notificationPreferences: update)

        let encoder = JSONEncoder()
        let data = try encoder.encode(request)
        let json = try JSONSerialization.jsonObject(with: data) as! [String: Any]
        let prefs = json["notification_preferences"] as! [String: Any]

        XCTAssertEqual(prefs["reservations_enabled"] as? Bool, true)
        XCTAssertNil(prefs["group_activity_enabled"])
        XCTAssertEqual(prefs["reminders_enabled"] as? Bool, false)
        XCTAssertNil(prefs["reminder_24h_enabled"])
        XCTAssertEqual(prefs["reminder_2h_enabled"] as? Bool, true)
    }

    // MARK: - Equatable Tests

    func testNotificationPreferencesEquality() {
        let prefs1 = NotificationPreferences(
            id: 1,
            userId: 42,
            reservationsEnabled: true,
            groupActivityEnabled: true,
            remindersEnabled: true,
            reminder24HEnabled: true,
            reminder2HEnabled: false
        )

        let prefs2 = NotificationPreferences(
            id: 1,
            userId: 42,
            reservationsEnabled: true,
            groupActivityEnabled: true,
            remindersEnabled: true,
            reminder24HEnabled: true,
            reminder2HEnabled: false
        )

        XCTAssertEqual(prefs1, prefs2)
    }

    func testNotificationPreferencesInequality() {
        let prefs1 = NotificationPreferences(
            id: 1,
            userId: 42,
            reservationsEnabled: true,
            groupActivityEnabled: true,
            remindersEnabled: true,
            reminder24HEnabled: true,
            reminder2HEnabled: false
        )

        let prefs2 = NotificationPreferences(
            id: 1,
            userId: 42,
            reservationsEnabled: true,
            groupActivityEnabled: true,
            remindersEnabled: true,
            reminder24HEnabled: false, // Different
            reminder2HEnabled: false
        )

        XCTAssertNotEqual(prefs1, prefs2)
    }

    // MARK: - Default Preferences Tests

    func testDefaultPreferences() {
        let defaults = NotificationPreferences.defaultPreferences

        XCTAssertEqual(defaults.id, 0)
        XCTAssertEqual(defaults.userId, 0)
        XCTAssertTrue(defaults.reservationsEnabled)
        XCTAssertTrue(defaults.groupActivityEnabled)
        XCTAssertTrue(defaults.remindersEnabled)
        XCTAssertTrue(defaults.reminder24HEnabled)
        XCTAssertTrue(defaults.reminder2HEnabled)
    }
}

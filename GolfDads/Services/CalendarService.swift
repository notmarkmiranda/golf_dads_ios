//
//  CalendarService.swift
//  GolfDads
//

import Foundation
import EventKit

/// Errors that can occur during calendar operations
enum CalendarError: LocalizedError {
    case permissionDenied
    case eventNotFound
    case eventStoreUnavailable
    case failedToSave(Error)
    case failedToDelete(Error)

    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Calendar access was denied. Please enable calendar access in Settings."
        case .eventNotFound:
            return "The calendar event could not be found."
        case .eventStoreUnavailable:
            return "Calendar is not available on this device."
        case .failedToSave(let error):
            return "Failed to save calendar event: \(error.localizedDescription)"
        case .failedToDelete(let error):
            return "Failed to delete calendar event: \(error.localizedDescription)"
        }
    }
}

/// Protocol for calendar operations (enables mocking for tests)
protocol CalendarServiceProtocol {
    /// Request calendar access permission from the user
    func requestCalendarAccess() async -> Bool

    /// Check if the app currently has calendar access
    func hasCalendarAccess() async -> Bool

    /// Create a new calendar event
    /// - Returns: Event identifier string for tracking
    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?,
        url: URL?
    ) async throws -> String

    /// Update an existing calendar event
    func updateEvent(
        eventId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?,
        url: URL?
    ) async throws

    /// Delete a calendar event
    func deleteEvent(eventId: String) async throws

    /// Check if an event exists in the calendar
    func eventExists(eventId: String) -> Bool
}

/// Calendar service for managing iOS calendar events
class CalendarService: CalendarServiceProtocol {

    // MARK: - Properties

    private let eventStore: EKEventStore
    private var permissionGrantedInSession = false

    // MARK: - Initialization

    init() {
        self.eventStore = EKEventStore()
    }

    // MARK: - Permission Management

    func requestCalendarAccess() async -> Bool {
        // iOS 17+ uses new permission model
        if #available(iOS 17.0, *) {
            do {
                // Request write-only access (which is what we need for creating events)
                let granted = try await eventStore.requestWriteOnlyAccessToEvents()
                print("📅 Calendar write-only permission result: \(granted)")

                // Store the result in session
                permissionGrantedInSession = granted

                // Give system time to update authorization status
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms

                // Check the actual authorization status
                let status = EKEventStore.authorizationStatus(for: .event)
                print("📅 Authorization status after request: \(status.rawValue)")

                return granted
            } catch {
                print("❌ Calendar permission request failed: \(error)")
                permissionGrantedInSession = false
                return false
            }
        } else {
            // iOS 16 and earlier
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        print("❌ Calendar permission request failed: \(error)")
                    }
                    self.permissionGrantedInSession = granted
                    print("📅 Calendar permission: \(granted ? "granted" : "denied")")
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func hasCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            print("📅 iOS 17+ authorization status: \(status.rawValue) - fullAccess=\(status == .fullAccess), writeOnly=\(status == .writeOnly)")

            // If permission was granted in this session, trust that even if status check fails
            if permissionGrantedInSession {
                print("📅 Permission was granted in this session, using that")
                return true
            }

            return status == .fullAccess || status == .writeOnly
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
            print("📅 iOS <17 authorization status: \(status.rawValue) - authorized=\(status == .authorized)")

            // If permission was granted in this session, trust that
            if permissionGrantedInSession {
                print("📅 Permission was granted in this session, using that")
                return true
            }

            return status == .authorized
        }
    }

    // MARK: - Calendar Event Operations

    func createEvent(
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?,
        url: URL?
    ) async throws -> String {
        // Verify permission
        let hasAccess = await hasCalendarAccess()
        print("📅 Attempting to create event, hasAccess: \(hasAccess)")

        guard hasAccess else {
            throw CalendarError.permissionDenied
        }

        // Check if we have a default calendar
        guard let defaultCalendar = eventStore.defaultCalendarForNewEvents else {
            print("❌ No default calendar found")
            throw CalendarError.eventStoreUnavailable
        }
        print("📅 Using default calendar: \(defaultCalendar.title)")

        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.url = url
        event.calendar = defaultCalendar

        // Save event
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Calendar event created: \(title) at \(startDate)")
            return event.eventIdentifier
        } catch {
            print("❌ Failed to create calendar event: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw CalendarError.failedToSave(error)
        }
    }

    func updateEvent(
        eventId: String,
        title: String,
        startDate: Date,
        endDate: Date,
        location: String?,
        notes: String?,
        url: URL?
    ) async throws {
        // Verify permission
        guard await hasCalendarAccess() else {
            throw CalendarError.permissionDenied
        }

        // Fetch existing event
        guard let event = eventStore.event(withIdentifier: eventId) else {
            throw CalendarError.eventNotFound
        }

        // Update event properties
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.url = url

        // Save changes
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Calendar event updated: \(title) at \(startDate)")
        } catch {
            print("❌ Failed to update calendar event: \(error)")
            throw CalendarError.failedToSave(error)
        }
    }

    func deleteEvent(eventId: String) async throws {
        // Verify permission
        guard await hasCalendarAccess() else {
            throw CalendarError.permissionDenied
        }

        // Fetch existing event
        guard let event = eventStore.event(withIdentifier: eventId) else {
            // Event already deleted or doesn't exist - not an error
            print("⚠️ Calendar event not found (already deleted?): \(eventId)")
            return
        }

        // Delete event
        do {
            try eventStore.remove(event, span: .thisEvent)
            print("✅ Calendar event deleted: \(event.title ?? eventId)")
        } catch {
            print("❌ Failed to delete calendar event: \(error)")
            throw CalendarError.failedToDelete(error)
        }
    }

    func eventExists(eventId: String) -> Bool {
        return eventStore.event(withIdentifier: eventId) != nil
    }
}

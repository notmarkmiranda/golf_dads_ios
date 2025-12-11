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

    // MARK: - Initialization

    init() {
        self.eventStore = EKEventStore()
    }

    // MARK: - Permission Management

    func requestCalendarAccess() async -> Bool {
        // iOS 17+ uses new permission model
        if #available(iOS 17.0, *) {
            do {
                let granted = try await eventStore.requestFullAccessToEvents()
                print("📅 Calendar permission: \(granted ? "granted" : "denied")")
                return granted
            } catch {
                print("❌ Calendar permission request failed: \(error)")
                return false
            }
        } else {
            // iOS 16 and earlier
            return await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { granted, error in
                    if let error = error {
                        print("❌ Calendar permission request failed: \(error)")
                    }
                    print("📅 Calendar permission: \(granted ? "granted" : "denied")")
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func hasCalendarAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            let status = EKEventStore.authorizationStatus(for: .event)
            return status == .fullAccess || status == .writeOnly
        } else {
            let status = EKEventStore.authorizationStatus(for: .event)
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
        guard await hasCalendarAccess() else {
            throw CalendarError.permissionDenied
        }

        // Create event
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.notes = notes
        event.url = url
        event.calendar = eventStore.defaultCalendarForNewEvents

        // Save event
        do {
            try eventStore.save(event, span: .thisEvent)
            print("✅ Calendar event created: \(title) at \(startDate)")
            return event.eventIdentifier
        } catch {
            print("❌ Failed to create calendar event: \(error)")
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

//
//  CalendarSyncManager.swift
//  GolfDads
//

import Foundation
import Combine

/// Manager for orchestrating calendar sync operations
@MainActor
class CalendarSyncManager: ObservableObject {

    // MARK: - Properties

    private let calendarService: CalendarServiceProtocol
    private let storageService: CalendarEventStorageProtocol

    @Published private(set) var hasCalendarPermission: Bool = false
    @Published private(set) var isSyncing: Bool = false

    // MARK: - Initialization

    init(
        calendarService: CalendarServiceProtocol = CalendarService(),
        storageService: CalendarEventStorageProtocol = CalendarEventStorageService()
    ) {
        self.calendarService = calendarService
        self.storageService = storageService
    }

    // MARK: - Permission Management

    func checkPermission() async {
        hasCalendarPermission = await calendarService.hasCalendarAccess()
    }

    func requestPermission() async -> Bool {
        let granted = await calendarService.requestCalendarAccess()
        hasCalendarPermission = granted
        return granted
    }

    // MARK: - Reservation Operations

    /// Sync a reservation to calendar
    /// - Parameters:
    ///   - reservation: The reservation to sync
    ///   - shouldPromptUser: Whether to prompt for permission if needed
    /// - Returns: True if sync succeeded, false otherwise
    @discardableResult
    func syncReservation(_ reservation: Reservation, shouldPromptUser: Bool) async -> Bool {
        // Check permission
        guard await ensurePermission(shouldPromptUser: shouldPromptUser) else {
            return false
        }

        // Verify we have posting info
        guard let snapshot = SyncSnapshot.from(reservation: reservation) else {
            print("⚠️ Cannot sync reservation \(reservation.id) - missing posting info")
            return false
        }

        // Check if already synced
        if let existing = storageService.getMapping(entityType: .reservation, entityId: reservation.id) {
            print("⚠️ Reservation \(reservation.id) already synced to calendar")
            // Update it instead
            await updateReservationIfNeeded(reservation)
            return true
        }

        // Generate event details
        guard let details = generateEventDetails(for: reservation) else {
            return false
        }

        // Create calendar event
        do {
            let eventId = try await calendarService.createEvent(
                title: details.title,
                startDate: details.startDate,
                endDate: details.endDate,
                location: details.location,
                notes: details.notes,
                url: details.url
            )

            // Save mapping
            let mapping = CalendarEventMapping.forReservation(
                reservationId: reservation.id,
                calendarEventId: eventId,
                snapshot: snapshot
            )
            storageService.saveMapping(mapping)

            print("✅ Synced reservation \(reservation.id) to calendar")
            return true
        } catch {
            print("❌ Failed to sync reservation to calendar: \(error)")
            return false
        }
    }

    /// Update reservation calendar event if data has changed
    func updateReservationIfNeeded(_ reservation: Reservation) async {
        // Get existing mapping
        guard let mapping = storageService.getMapping(entityType: .reservation, entityId: reservation.id) else {
            return  // Not synced yet
        }

        // Get current snapshot
        guard let currentSnapshot = SyncSnapshot.from(reservation: reservation) else {
            print("⚠️ Cannot update reservation \(reservation.id) - missing posting info")
            return
        }

        // Check if changed
        guard currentSnapshot != mapping.lastSyncedData else {
            return  // No changes
        }

        print("🔄 Detected changes in reservation \(reservation.id) - updating calendar")

        // Generate new event details
        guard let details = generateEventDetails(for: reservation) else {
            return
        }

        // Update calendar event
        do {
            try await calendarService.updateEvent(
                eventId: mapping.calendarEventId,
                title: details.title,
                startDate: details.startDate,
                endDate: details.endDate,
                location: details.location,
                notes: details.notes,
                url: details.url
            )

            // Update mapping with new snapshot
            let updatedMapping = CalendarEventMapping.forReservation(
                reservationId: reservation.id,
                calendarEventId: mapping.calendarEventId,
                snapshot: currentSnapshot
            )
            storageService.saveMapping(updatedMapping)

            print("✅ Updated reservation \(reservation.id) calendar event")
        } catch {
            print("❌ Failed to update reservation calendar event: \(error)")
        }
    }

    /// Remove reservation from calendar
    func removeReservation(reservationId: Int) async {
        guard let mapping = storageService.getMapping(entityType: .reservation, entityId: reservationId) else {
            return  // Not synced
        }

        // Delete calendar event
        do {
            try await calendarService.deleteEvent(eventId: mapping.calendarEventId)
            storageService.deleteMapping(entityType: .reservation, entityId: reservationId)
            print("✅ Removed reservation \(reservationId) from calendar")
        } catch {
            print("❌ Failed to remove reservation from calendar: \(error)")
            // Delete mapping anyway (event might already be gone)
            storageService.deleteMapping(entityType: .reservation, entityId: reservationId)
        }
    }

    // MARK: - Posting Operations

    /// Sync a posting to calendar
    @discardableResult
    func syncPosting(_ posting: TeeTimePosting, shouldPromptUser: Bool) async -> Bool {
        // Check permission
        guard await ensurePermission(shouldPromptUser: shouldPromptUser) else {
            return false
        }

        let snapshot = SyncSnapshot.from(posting: posting)

        // Check if already synced
        if let existing = storageService.getMapping(entityType: .posting, entityId: posting.id) {
            print("⚠️ Posting \(posting.id) already synced to calendar")
            // Update it instead
            await updatePostingIfNeeded(posting)
            return true
        }

        // Generate event details
        let details = generateEventDetails(for: posting)

        // Create calendar event
        do {
            let eventId = try await calendarService.createEvent(
                title: details.title,
                startDate: details.startDate,
                endDate: details.endDate,
                location: details.location,
                notes: details.notes,
                url: details.url
            )

            // Save mapping
            let mapping = CalendarEventMapping.forPosting(
                postingId: posting.id,
                calendarEventId: eventId,
                snapshot: snapshot
            )
            storageService.saveMapping(mapping)

            print("✅ Synced posting \(posting.id) to calendar")
            return true
        } catch {
            print("❌ Failed to sync posting to calendar: \(error)")
            return false
        }
    }

    /// Update posting calendar event if data has changed
    func updatePostingIfNeeded(_ posting: TeeTimePosting) async {
        // Get existing mapping
        guard let mapping = storageService.getMapping(entityType: .posting, entityId: posting.id) else {
            return  // Not synced yet
        }

        // Get current snapshot
        let currentSnapshot = SyncSnapshot.from(posting: posting)

        // Check if changed
        guard currentSnapshot != mapping.lastSyncedData else {
            return  // No changes
        }

        print("🔄 Detected changes in posting \(posting.id) - updating calendar")

        // Generate new event details
        let details = generateEventDetails(for: posting)

        // Update calendar event
        do {
            try await calendarService.updateEvent(
                eventId: mapping.calendarEventId,
                title: details.title,
                startDate: details.startDate,
                endDate: details.endDate,
                location: details.location,
                notes: details.notes,
                url: details.url
            )

            // Update mapping with new snapshot
            let updatedMapping = CalendarEventMapping.forPosting(
                postingId: posting.id,
                calendarEventId: mapping.calendarEventId,
                snapshot: currentSnapshot
            )
            storageService.saveMapping(updatedMapping)

            print("✅ Updated posting \(posting.id) calendar event")
        } catch {
            print("❌ Failed to update posting calendar event: \(error)")
        }
    }

    /// Remove posting from calendar
    func removePosting(postingId: Int) async {
        guard let mapping = storageService.getMapping(entityType: .posting, entityId: postingId) else {
            return  // Not synced
        }

        // Delete calendar event
        do {
            try await calendarService.deleteEvent(eventId: mapping.calendarEventId)
            storageService.deleteMapping(entityType: .posting, entityId: postingId)
            print("✅ Removed posting \(postingId) from calendar")
        } catch {
            print("❌ Failed to remove posting from calendar: \(error)")
            // Delete mapping anyway
            storageService.deleteMapping(entityType: .posting, entityId: postingId)
        }
    }

    // MARK: - Bulk Operations

    /// Sync all reservations (checks for changes)
    func syncAllReservations(_ reservations: [Reservation]) async {
        guard hasCalendarPermission else {
            return
        }

        for reservation in reservations {
            await updateReservationIfNeeded(reservation)
        }
    }

    /// Sync all postings (checks for changes)
    func syncAllPostings(_ postings: [TeeTimePosting]) async {
        guard hasCalendarPermission else {
            return
        }

        for posting in postings {
            await updatePostingIfNeeded(posting)
        }
    }

    /// Cleanup calendar events that no longer exist in app data
    func cleanupDeletedEvents(
        currentReservations: [Reservation],
        currentPostings: [TeeTimePosting]
    ) async {
        let allMappings = storageService.getAllMappings()

        let currentReservationIds = Set(currentReservations.map { $0.id })
        let currentPostingIds = Set(currentPostings.map { $0.id })

        for mapping in allMappings {
            switch mapping.entityType {
            case .reservation:
                if !currentReservationIds.contains(mapping.entityId) {
                    print("🗑️ Cleaning up deleted reservation \(mapping.entityId)")
                    await removeReservation(reservationId: mapping.entityId)
                }
            case .posting:
                if !currentPostingIds.contains(mapping.entityId) {
                    print("🗑️ Cleaning up deleted posting \(mapping.entityId)")
                    await removePosting(postingId: mapping.entityId)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func ensurePermission(shouldPromptUser: Bool) async -> Bool {
        if await calendarService.hasCalendarAccess() {
            hasCalendarPermission = true
            return true
        }

        if shouldPromptUser {
            return await requestPermission()
        }

        return false
    }

    private struct EventDetails {
        let title: String
        let startDate: Date
        let endDate: Date
        let location: String?
        let notes: String?
        let url: URL?
    }

    private func generateEventDetails(for reservation: Reservation) -> EventDetails? {
        guard let posting = reservation.teeTimePosting else {
            return nil
        }

        let title = "Golf at \(posting.courseName)"
        let startDate = posting.teeTime
        let endDate = startDate.addingTimeInterval(4 * 3600)  // 4 hours
        let location = posting.courseName

        var notesText = ""
        if let postingNotes = posting.notes, !postingNotes.isEmpty {
            notesText += "Notes: \(postingNotes)\n\n"
        }
        notesText += "Spots Reserved: \(reservation.spotsReserved)\n"
        notesText += "Via Three Putt Golf App"

        return EventDetails(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            notes: notesText,
            url: nil
        )
    }

    private func generateEventDetails(for posting: TeeTimePosting) -> EventDetails {
        let title = "Golf at \(posting.displayCourseName)"
        let startDate = posting.teeTime
        let endDate = startDate.addingTimeInterval(4 * 3600)  // 4 hours

        // Build location from golf course info
        let location: String
        if let golfCourse = posting.golfCourse {
            var parts: [String] = [golfCourse.name]
            if let address = golfCourse.address {
                parts.append(address)
            }
            if let city = golfCourse.city, let state = golfCourse.state {
                parts.append("\(city), \(state)")
            }
            if let zip = golfCourse.zipCode {
                parts.append(zip)
            }
            location = parts.joined(separator: ", ")
        } else {
            location = posting.courseName
        }

        var notesText = ""
        if let postingNotes = posting.notes, !postingNotes.isEmpty {
            notesText += "Notes: \(postingNotes)\n\n"
        }
        notesText += "Posted by: You\n"
        notesText += "Available Spots: \(posting.availableSpots)\n"
        notesText += "Via Three Putt Golf App"

        return EventDetails(
            title: title,
            startDate: startDate,
            endDate: endDate,
            location: location,
            notes: notesText,
            url: nil
        )
    }
}

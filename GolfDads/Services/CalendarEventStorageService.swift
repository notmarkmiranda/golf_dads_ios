//
//  CalendarEventStorageService.swift
//  GolfDads
//

import Foundation

/// Type of entity linked to calendar event
enum CalendarEntityType: String, Codable {
    case reservation
    case posting
}

/// Snapshot of synced data for change detection
struct SyncSnapshot: Codable, Equatable {
    let courseName: String
    let teeTime: Date
    let notes: String?
    let location: String?

    /// Create snapshot from a Reservation
    static func from(reservation: Reservation) -> SyncSnapshot? {
        guard let posting = reservation.teeTimePosting else {
            return nil
        }

        return SyncSnapshot(
            courseName: posting.courseName,
            teeTime: posting.teeTime,
            notes: posting.notes,
            location: posting.courseName  // Fallback to course name
        )
    }

    /// Create snapshot from a TeeTimePosting
    static func from(posting: TeeTimePosting) -> SyncSnapshot {
        let location: String
        if let golfCourse = posting.golfCourse {
            // Build full address
            var parts: [String] = [golfCourse.name]
            if let address = golfCourse.address {
                parts.append(address)
            }
            if let city = golfCourse.city, let state = golfCourse.state {
                parts.append("\(city), \(state)")
            } else if let city = golfCourse.city {
                parts.append(city)
            } else if let state = golfCourse.state {
                parts.append(state)
            }
            if let zip = golfCourse.zipCode {
                parts.append(zip)
            }
            location = parts.joined(separator: ", ")
        } else {
            location = posting.courseName
        }

        return SyncSnapshot(
            courseName: posting.displayCourseName,
            teeTime: posting.teeTime,
            notes: posting.notes,
            location: location
        )
    }
}

/// Mapping between app entity and calendar event
struct CalendarEventMapping: Codable {
    let entityType: CalendarEntityType
    let entityId: Int
    let calendarEventId: String
    let lastSyncedData: SyncSnapshot
    let createdAt: Date

    /// Create mapping for a reservation
    static func forReservation(
        reservationId: Int,
        calendarEventId: String,
        snapshot: SyncSnapshot
    ) -> CalendarEventMapping {
        CalendarEventMapping(
            entityType: .reservation,
            entityId: reservationId,
            calendarEventId: calendarEventId,
            lastSyncedData: snapshot,
            createdAt: Date()
        )
    }

    /// Create mapping for a posting
    static func forPosting(
        postingId: Int,
        calendarEventId: String,
        snapshot: SyncSnapshot
    ) -> CalendarEventMapping {
        CalendarEventMapping(
            entityType: .posting,
            entityId: postingId,
            calendarEventId: calendarEventId,
            lastSyncedData: snapshot,
            createdAt: Date()
        )
    }
}

/// Protocol for calendar event storage operations
protocol CalendarEventStorageProtocol {
    /// Save a mapping
    func saveMapping(_ mapping: CalendarEventMapping)

    /// Get mapping for a specific entity
    func getMapping(entityType: CalendarEntityType, entityId: Int) -> CalendarEventMapping?

    /// Get all mappings
    func getAllMappings() -> [CalendarEventMapping]

    /// Delete a specific mapping
    func deleteMapping(entityType: CalendarEntityType, entityId: Int)

    /// Clear all mappings
    func clearAllMappings()
}

/// Storage service for calendar event mappings using UserDefaults
class CalendarEventStorageService: CalendarEventStorageProtocol {

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let storageKey = "calendar_events_mappings"

    // MARK: - Initialization

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    // MARK: - Storage Operations

    func saveMapping(_ mapping: CalendarEventMapping) {
        var mappings = getAllMappings()

        // Remove existing mapping for this entity (if any)
        mappings.removeAll { $0.entityType == mapping.entityType && $0.entityId == mapping.entityId }

        // Add new mapping
        mappings.append(mapping)

        // Save to UserDefaults
        save(mappings: mappings)

        print("💾 Saved calendar mapping: \(mapping.entityType) #\(mapping.entityId) → \(mapping.calendarEventId)")
    }

    func getMapping(entityType: CalendarEntityType, entityId: Int) -> CalendarEventMapping? {
        let mappings = getAllMappings()
        return mappings.first { $0.entityType == entityType && $0.entityId == entityId }
    }

    func getAllMappings() -> [CalendarEventMapping] {
        guard let data = userDefaults.data(forKey: storageKey) else {
            return []
        }

        do {
            let mappings = try JSONDecoder().decode([CalendarEventMapping].self, from: data)
            return mappings
        } catch {
            print("❌ Failed to decode calendar mappings: \(error)")
            return []
        }
    }

    func deleteMapping(entityType: CalendarEntityType, entityId: Int) {
        var mappings = getAllMappings()
        mappings.removeAll { $0.entityType == entityType && $0.entityId == entityId }
        save(mappings: mappings)

        print("🗑️ Deleted calendar mapping: \(entityType) #\(entityId)")
    }

    func clearAllMappings() {
        userDefaults.removeObject(forKey: storageKey)
        print("🗑️ Cleared all calendar mappings")
    }

    // MARK: - Private Methods

    private func save(mappings: [CalendarEventMapping]) {
        do {
            let data = try JSONEncoder().encode(mappings)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save calendar mappings: \(error)")
        }
    }
}

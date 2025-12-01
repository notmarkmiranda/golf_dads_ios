//
//  TeeTimePostingTests.swift
//  GolfDadsTests
//
//  Tests for TeeTimePosting model Codable conformance
//

import XCTest
@testable import GolfDads

final class TeeTimePostingTests: XCTestCase {

    // MARK: - Decoding Tests

    func testDecodePublicTeeTimePostingFromJSON() throws {
        // Given - Public posting (empty group_ids array)
        let json = """
        {
            "id": 1,
            "user_id": 42,
            "group_ids": [],
            "tee_time": "2024-06-15T14:30:00Z",
            "course_name": "Pebble Beach",
            "available_spots": 2,
            "total_spots": 4,
            "notes": "Looking for 2 more players",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let posting = try decoder.decode(TeeTimePosting.self, from: json)

        // Then
        XCTAssertEqual(posting.id, 1)
        XCTAssertEqual(posting.userId, 42)
        XCTAssertTrue(posting.groupIds.isEmpty)
        XCTAssertEqual(posting.courseName, "Pebble Beach")
        XCTAssertEqual(posting.availableSpots, 2)
        XCTAssertEqual(posting.totalSpots, 4)
        XCTAssertEqual(posting.notes, "Looking for 2 more players")
        XCTAssertNotNil(posting.teeTime)
        XCTAssertNotNil(posting.createdAt)
        XCTAssertNotNil(posting.updatedAt)
    }

    func testDecodeGroupTeeTimePostingFromJSON() throws {
        // Given - Group posting (has group_ids)
        let json = """
        {
            "id": 2,
            "user_id": 10,
            "group_ids": [5, 7],
            "tee_time": "2024-06-20T09:00:00Z",
            "course_name": "Augusta National",
            "available_spots": 3,
            "total_spots": null,
            "notes": null,
            "created_at": "2024-01-16T10:30:00Z",
            "updated_at": "2024-01-16T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let posting = try decoder.decode(TeeTimePosting.self, from: json)

        // Then
        XCTAssertEqual(posting.id, 2)
        XCTAssertEqual(posting.userId, 10)
        XCTAssertEqual(posting.groupIds, [5, 7])
        XCTAssertEqual(posting.courseName, "Augusta National")
        XCTAssertEqual(posting.availableSpots, 3)
        XCTAssertNil(posting.totalSpots)
        XCTAssertNil(posting.notes)
    }

    func testDecodeTeeTimePostingArray() throws {
        // Given
        let json = """
        [
            {
                "id": 1,
                "user_id": 1,
                "group_ids": [],
                "tee_time": "2024-06-15T14:30:00Z",
                "course_name": "Course One",
                "available_spots": 2,
                "total_spots": 4,
                "notes": "Notes",
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            },
            {
                "id": 2,
                "user_id": 2,
                "group_ids": [1],
                "tee_time": "2024-06-16T09:00:00Z",
                "course_name": "Course Two",
                "available_spots": 1,
                "total_spots": null,
                "notes": null,
                "created_at": "2024-01-16T10:30:00Z",
                "updated_at": "2024-01-16T10:30:00Z"
            }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let postings = try decoder.decode([TeeTimePosting].self, from: json)

        // Then
        XCTAssertEqual(postings.count, 2)
        XCTAssertEqual(postings[0].id, 1)
        XCTAssertEqual(postings[1].id, 2)
        XCTAssertTrue(postings[0].groupIds.isEmpty)
        XCTAssertEqual(postings[1].groupIds, [1])
    }

    // MARK: - Encoding Tests

    func testEncodeTeeTimePostingToJSON() throws {
        // Given
        let posting = TeeTimePosting(
            id: 1,
            userId: 42,
            groupIds: [],
            teeTime: Date(timeIntervalSince1970: 1718462400), // 2024-06-15T14:00:00Z
            courseName: "Test Course",
            availableSpots: 2,
            totalSpots: 4,
            notes: "Test notes",
            createdAt: Date(timeIntervalSince1970: 1705315800),
            updatedAt: Date(timeIntervalSince1970: 1705315800)
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        // When
        let data = try encoder.encode(posting)
        let json = String(data: data, encoding: .utf8)!

        // Then
        XCTAssertTrue(json.contains("\"id\":1"))
        XCTAssertTrue(json.contains("\"user_id\":42"))
        XCTAssertTrue(json.contains("\"course_name\":\"Test Course\""))
        XCTAssertTrue(json.contains("\"available_spots\":2"))
        XCTAssertTrue(json.contains("\"total_spots\":4"))
    }

    // MARK: - Computed Properties Tests

    func testIsPublicWhenGroupIdsIsEmpty() {
        // Given
        let posting = TeeTimePosting(
            id: 1,
            userId: 1,
            groupIds: [],
            teeTime: Date(),
            courseName: "Test",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertTrue(posting.isPublic)
    }

    func testIsNotPublicWhenGroupIdsExists() {
        // Given
        let posting = TeeTimePosting(
            id: 1,
            userId: 1,
            groupIds: [5],
            teeTime: Date(),
            courseName: "Test",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertFalse(posting.isPublic)
    }

    func testIsPastWhenTeeTimeIsInPast() {
        // Given
        let pastDate = Date().addingTimeInterval(-86400) // 1 day ago
        let posting = TeeTimePosting(
            id: 1,
            userId: 1,
            groupIds: [],
            teeTime: pastDate,
            courseName: "Test",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertTrue(posting.isPast)
    }

    func testIsNotPastWhenTeeTimeIsInFuture() {
        // Given
        let futureDate = Date().addingTimeInterval(86400) // 1 day from now
        let posting = TeeTimePosting(
            id: 1,
            userId: 1,
            groupIds: [],
            teeTime: futureDate,
            courseName: "Test",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertFalse(posting.isPast)
    }

    // MARK: - Equatable Tests

    func testTeeTimePostingEquality() {
        // Given
        let date = Date()
        let posting1 = TeeTimePosting(
            id: 1,
            userId: 42,
            groupIds: [],
            teeTime: date,
            courseName: "Test",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: date,
            updatedAt: date
        )

        let posting2 = TeeTimePosting(
            id: 1,
            userId: 42,
            groupIds: [],
            teeTime: date,
            courseName: "Test",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: date,
            updatedAt: date
        )

        let posting3 = TeeTimePosting(
            id: 2,
            userId: 42,
            groupIds: [],
            teeTime: date,
            courseName: "Different",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: date,
            updatedAt: date
        )

        // Then
        XCTAssertEqual(posting1, posting2)
        XCTAssertNotEqual(posting1, posting3)
    }

    // MARK: - Identifiable Tests

    func testTeeTimePostingIdentifiable() {
        // Given
        let posting = TeeTimePosting(
            id: 123,
            userId: 1,
            groupIds: [],
            teeTime: Date(),
            courseName: "Test",
            availableSpots: 2,
            totalSpots: 4,
            notes: nil,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertEqual(posting.id, 123)
    }

    // MARK: - Reservations Tests

    func testDecodeWithReservations() throws {
        // Given - Posting with reservations (owner view)
        let json = """
        {
            "id": 1,
            "user_id": 42,
            "group_ids": [],
            "tee_time": "2024-06-15T14:30:00Z",
            "course_name": "Pebble Beach",
            "available_spots": 1,
            "total_spots": 4,
            "notes": "Looking for more players",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z",
            "reservations": [
                {
                    "id": 1,
                    "user_email": "player1@example.com",
                    "spots_reserved": 2,
                    "created_at": "2024-01-15T11:00:00Z"
                },
                {
                    "id": 2,
                    "user_email": "player2@example.com",
                    "spots_reserved": 1,
                    "created_at": "2024-01-15T12:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let posting = try decoder.decode(TeeTimePosting.self, from: json)

        // Then
        XCTAssertEqual(posting.id, 1)
        XCTAssertEqual(posting.availableSpots, 1)
        XCTAssertNotNil(posting.reservations)
        XCTAssertEqual(posting.reservations?.count, 2)
        XCTAssertEqual(posting.reservations?[0].userEmail, "player1@example.com")
        XCTAssertEqual(posting.reservations?[0].spotsReserved, 2)
        XCTAssertEqual(posting.reservations?[1].userEmail, "player2@example.com")
        XCTAssertEqual(posting.reservations?[1].spotsReserved, 1)
    }

    func testDecodeWithoutReservations() throws {
        // Given - Posting without reservations (non-owner view)
        let json = """
        {
            "id": 1,
            "user_id": 42,
            "group_ids": [],
            "tee_time": "2024-06-15T14:30:00Z",
            "course_name": "Pebble Beach",
            "available_spots": 2,
            "total_spots": 4,
            "notes": "Looking for 2 more players",
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let posting = try decoder.decode(TeeTimePosting.self, from: json)

        // Then
        XCTAssertEqual(posting.id, 1)
        XCTAssertNil(posting.reservations)
    }
}

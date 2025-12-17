//
//  TeeTimeServiceResponseTests.swift
//  GolfDadsTests
//
//  Tests for TeeTimeService response decoding from API
//

import XCTest
@testable import GolfDads

final class TeeTimeServiceResponseTests: XCTestCase {

    // MARK: - Tee Time Postings List Response Tests

    func testDecodeTeeTimePostingsListResponse() throws {
        // Given - Response with snake_case keys from API
        let json = """
        {
            "tee_time_postings": [
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
                },
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
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When - Define local Response struct matching the service
        struct Response: Codable {
            let teeTimePostings: [TeeTimePosting]
        }

        let response = try decoder.decode(Response.self, from: json)

        // Then
        XCTAssertEqual(response.teeTimePostings.count, 2)

        // Verify first posting
        let firstPosting = response.teeTimePostings[0]
        XCTAssertEqual(firstPosting.id, 1)
        XCTAssertEqual(firstPosting.userId, 42)
        XCTAssertTrue(firstPosting.groupIds.isEmpty)
        XCTAssertEqual(firstPosting.courseName, "Pebble Beach")
        XCTAssertEqual(firstPosting.availableSpots, 2)
        XCTAssertEqual(firstPosting.totalSpots, 4)
        XCTAssertEqual(firstPosting.notes, "Looking for 2 more players")

        // Verify second posting
        let secondPosting = response.teeTimePostings[1]
        XCTAssertEqual(secondPosting.id, 2)
        XCTAssertEqual(secondPosting.userId, 10)
        XCTAssertEqual(secondPosting.groupIds, [5, 7])
        XCTAssertEqual(secondPosting.courseName, "Augusta National")
        XCTAssertEqual(secondPosting.availableSpots, 3)
        XCTAssertNil(secondPosting.totalSpots)
        XCTAssertNil(secondPosting.notes)
    }

    func testDecodeEmptyTeeTimePostingsListResponse() throws {
        // Given - Empty response (user sees when no tee times available)
        let json = """
        {
            "tee_time_postings": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        struct Response: Codable {
            let teeTimePostings: [TeeTimePosting]
        }

        // When
        let response = try decoder.decode(Response.self, from: json)

        // Then
        XCTAssertTrue(response.teeTimePostings.isEmpty)
    }

    // MARK: - Single Tee Time Posting Response Tests

    func testDecodeSingleTeeTimePostingResponse() throws {
        // Given - Single posting response (for create/update/get by ID)
        let json = """
        {
            "tee_time_posting": {
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
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let teeTimePosting: TeeTimePosting
        }

        // When
        let response = try decoder.decode(Response.self, from: json)

        // Then
        XCTAssertEqual(response.teeTimePosting.id, 1)
        XCTAssertEqual(response.teeTimePosting.userId, 42)
        XCTAssertEqual(response.teeTimePosting.courseName, "Pebble Beach")
        XCTAssertEqual(response.teeTimePosting.availableSpots, 2)
        XCTAssertEqual(response.teeTimePosting.totalSpots, 4)
    }

    func testDecodeTeeTimePostingWithReservations() throws {
        // Given - Posting with reservations (owner view)
        let json = """
        {
            "tee_time_posting": {
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
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let teeTimePosting: TeeTimePosting
        }

        // When
        let response = try decoder.decode(Response.self, from: json)

        // Then
        XCTAssertEqual(response.teeTimePosting.id, 1)
        XCTAssertEqual(response.teeTimePosting.availableSpots, 1)
        XCTAssertNotNil(response.teeTimePosting.reservations)
        XCTAssertEqual(response.teeTimePosting.reservations?.count, 2)
        XCTAssertEqual(response.teeTimePosting.reservations?[0].userEmail, "player1@example.com")
        XCTAssertEqual(response.teeTimePosting.reservations?[0].spotsReserved, 2)
        XCTAssertEqual(response.teeTimePosting.reservations?[1].userEmail, "player2@example.com")
        XCTAssertEqual(response.teeTimePosting.reservations?[1].spotsReserved, 1)
    }

    // MARK: - Error Case Tests

    func testDecodeFailsWithoutSnakeCaseConversion() {
        // Given - Response with snake_case keys but no decoder strategy
        let json = """
        {
            "tee_time_postings": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // NOT setting keyDecodingStrategy

        struct Response: Codable {
            let teeTimePostings: [TeeTimePosting]
        }

        // When/Then - This should fail because decoder expects camelCase
        XCTAssertThrowsError(try decoder.decode(Response.self, from: json)) { error in
            // Verify it's the expected decoding error
            guard case DecodingError.keyNotFound(let key, _) = error else {
                XCTFail("Expected keyNotFound error, got \(error)")
                return
            }
            XCTAssertEqual(key.stringValue, "teeTimePostings")
        }
    }

    func testDecodeGroupTeeTimePostingsResponse() throws {
        // Given - Group-specific tee times response
        let json = """
        {
            "tee_time_postings": [
                {
                    "id": 3,
                    "user_id": 15,
                    "group_ids": [10],
                    "tee_time": "2024-07-01T08:00:00Z",
                    "course_name": "St. Andrews",
                    "available_spots": 4,
                    "total_spots": 4,
                    "notes": "Group outing",
                    "created_at": "2024-01-20T10:00:00Z",
                    "updated_at": "2024-01-20T10:00:00Z"
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let teeTimePostings: [TeeTimePosting]
        }

        // When
        let response = try decoder.decode(Response.self, from: json)

        // Then
        XCTAssertEqual(response.teeTimePostings.count, 1)
        let posting = response.teeTimePostings[0]
        XCTAssertEqual(posting.id, 3)
        XCTAssertEqual(posting.groupIds, [10])
        XCTAssertFalse(posting.isPublic) // Group tee time (has group_ids)
        XCTAssertEqual(posting.courseName, "St. Andrews")
    }
}

//
//  ReservationTests.swift
//  GolfDadsTests
//
//  Tests for Reservation model Codable conformance
//

import XCTest
@testable import GolfDads

final class ReservationTests: XCTestCase {

    // MARK: - Decoding Tests

    func testDecodeReservationFromJSON() throws {
        // Given
        let json = """
        {
            "id": 1,
            "user_id": 42,
            "tee_time_posting_id": 10,
            "spots_reserved": 2,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let reservation = try decoder.decode(Reservation.self, from: json)

        // Then
        XCTAssertEqual(reservation.id, 1)
        XCTAssertEqual(reservation.userId, 42)
        XCTAssertEqual(reservation.teeTimePostingId, 10)
        XCTAssertEqual(reservation.spotsReserved, 2)
        XCTAssertNotNil(reservation.createdAt)
        XCTAssertNotNil(reservation.updatedAt)
    }

    func testDecodeReservationWithSingleSpot() throws {
        // Given
        let json = """
        {
            "id": 2,
            "user_id": 15,
            "tee_time_posting_id": 20,
            "spots_reserved": 1,
            "created_at": "2024-01-16T10:30:00Z",
            "updated_at": "2024-01-16T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let reservation = try decoder.decode(Reservation.self, from: json)

        // Then
        XCTAssertEqual(reservation.id, 2)
        XCTAssertEqual(reservation.userId, 15)
        XCTAssertEqual(reservation.teeTimePostingId, 20)
        XCTAssertEqual(reservation.spotsReserved, 1)
    }

    func testDecodeReservationArray() throws {
        // Given
        let json = """
        [
            {
                "id": 1,
                "user_id": 1,
                "tee_time_posting_id": 10,
                "spots_reserved": 2,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            },
            {
                "id": 2,
                "user_id": 2,
                "tee_time_posting_id": 11,
                "spots_reserved": 1,
                "created_at": "2024-01-16T10:30:00Z",
                "updated_at": "2024-01-16T10:30:00Z"
            }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let reservations = try decoder.decode([Reservation].self, from: json)

        // Then
        XCTAssertEqual(reservations.count, 2)
        XCTAssertEqual(reservations[0].id, 1)
        XCTAssertEqual(reservations[1].id, 2)
        XCTAssertEqual(reservations[0].spotsReserved, 2)
        XCTAssertEqual(reservations[1].spotsReserved, 1)
    }

    // MARK: - Encoding Tests

    func testEncodeReservationToJSON() throws {
        // Given
        let reservation = Reservation(
            id: 1,
            userId: 42,
            teeTimePostingId: 10,
            spotsReserved: 2,
            createdAt: Date(timeIntervalSince1970: 1705315800),
            updatedAt: Date(timeIntervalSince1970: 1705315800)
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        // When
        let data = try encoder.encode(reservation)
        let json = String(data: data, encoding: .utf8)!

        // Then
        XCTAssertTrue(json.contains("\"id\":1"))
        XCTAssertTrue(json.contains("\"user_id\":42"))
        XCTAssertTrue(json.contains("\"tee_time_posting_id\":10"))
        XCTAssertTrue(json.contains("\"spots_reserved\":2"))
    }

    // MARK: - Equatable Tests

    func testReservationEquality() {
        // Given
        let date = Date()
        let reservation1 = Reservation(
            id: 1,
            userId: 42,
            teeTimePostingId: 10,
            spotsReserved: 2,
            createdAt: date,
            updatedAt: date
        )

        let reservation2 = Reservation(
            id: 1,
            userId: 42,
            teeTimePostingId: 10,
            spotsReserved: 2,
            createdAt: date,
            updatedAt: date
        )

        let reservation3 = Reservation(
            id: 2,
            userId: 42,
            teeTimePostingId: 10,
            spotsReserved: 3,
            createdAt: date,
            updatedAt: date
        )

        // Then
        XCTAssertEqual(reservation1, reservation2)
        XCTAssertNotEqual(reservation1, reservation3)
    }

    // MARK: - Identifiable Tests

    func testReservationIdentifiable() {
        // Given
        let reservation = Reservation(
            id: 123,
            userId: 1,
            teeTimePostingId: 10,
            spotsReserved: 2,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertEqual(reservation.id, 123)
    }
}

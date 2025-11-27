//
//  GroupTests.swift
//  GolfDadsTests
//
//  Tests for Group model Codable conformance
//

import XCTest
@testable import GolfDads

final class GroupTests: XCTestCase {

    // MARK: - Decoding Tests

    func testDecodeGroupFromJSON() throws {
        // Given
        let json = """
        {
            "id": 1,
            "name": "Weekend Warriors",
            "description": "Golf every Saturday morning",
            "owner_id": 42,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let group = try decoder.decode(Group.self, from: json)

        // Then
        XCTAssertEqual(group.id, 1)
        XCTAssertEqual(group.name, "Weekend Warriors")
        XCTAssertEqual(group.description, "Golf every Saturday morning")
        XCTAssertEqual(group.ownerId, 42)
        XCTAssertNotNil(group.createdAt)
        XCTAssertNotNil(group.updatedAt)
    }

    func testDecodeGroupWithNilDescription() throws {
        // Given
        let json = """
        {
            "id": 2,
            "name": "Morning Group",
            "description": null,
            "owner_id": 10,
            "created_at": "2024-01-15T10:30:00Z",
            "updated_at": "2024-01-15T10:30:00Z"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let group = try decoder.decode(Group.self, from: json)

        // Then
        XCTAssertEqual(group.id, 2)
        XCTAssertEqual(group.name, "Morning Group")
        XCTAssertNil(group.description)
        XCTAssertEqual(group.ownerId, 10)
    }

    func testDecodeGroupArray() throws {
        // Given
        let json = """
        [
            {
                "id": 1,
                "name": "Group One",
                "description": "First group",
                "owner_id": 1,
                "created_at": "2024-01-15T10:30:00Z",
                "updated_at": "2024-01-15T10:30:00Z"
            },
            {
                "id": 2,
                "name": "Group Two",
                "description": null,
                "owner_id": 2,
                "created_at": "2024-01-16T10:30:00Z",
                "updated_at": "2024-01-16T10:30:00Z"
            }
        ]
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601

        // When
        let groups = try decoder.decode([Group].self, from: json)

        // Then
        XCTAssertEqual(groups.count, 2)
        XCTAssertEqual(groups[0].id, 1)
        XCTAssertEqual(groups[1].id, 2)
    }

    // MARK: - Encoding Tests

    func testEncodeGroupToJSON() throws {
        // Given
        let group = Group(
            id: 1,
            name: "Test Group",
            description: "Test description",
            ownerId: 42,
            createdAt: Date(timeIntervalSince1970: 1705315800), // 2024-01-15T10:30:00Z
            updatedAt: Date(timeIntervalSince1970: 1705315800)
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601

        // When
        let data = try encoder.encode(group)
        let json = String(data: data, encoding: .utf8)!

        // Then
        XCTAssertTrue(json.contains("\"id\":1"))
        XCTAssertTrue(json.contains("\"name\":\"Test Group\""))
        XCTAssertTrue(json.contains("\"description\":\"Test description\""))
        XCTAssertTrue(json.contains("\"owner_id\":42"))
    }

    func testEncodeGroupWithNilDescription() throws {
        // Given
        let group = Group(
            id: 1,
            name: "Test Group",
            description: nil,
            ownerId: 42,
            createdAt: Date(),
            updatedAt: Date()
        )

        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase

        // When
        let data = try encoder.encode(group)
        let json = String(data: data, encoding: .utf8)!

        // Then
        XCTAssertTrue(json.contains("\"name\":\"Test Group\""))
        XCTAssertTrue(json.contains("\"owner_id\":42"))
    }

    // MARK: - Equatable Tests

    func testGroupEquality() {
        // Given
        let date = Date()
        let group1 = Group(
            id: 1,
            name: "Test Group",
            description: "Description",
            ownerId: 42,
            createdAt: date,
            updatedAt: date
        )

        let group2 = Group(
            id: 1,
            name: "Test Group",
            description: "Description",
            ownerId: 42,
            createdAt: date,
            updatedAt: date
        )

        let group3 = Group(
            id: 2,
            name: "Different Group",
            description: "Description",
            ownerId: 42,
            createdAt: date,
            updatedAt: date
        )

        // Then
        XCTAssertEqual(group1, group2)
        XCTAssertNotEqual(group1, group3)
    }

    // MARK: - Identifiable Tests

    func testGroupIdentifiable() {
        // Given
        let group = Group(
            id: 123,
            name: "Test Group",
            description: nil,
            ownerId: 1,
            createdAt: Date(),
            updatedAt: Date()
        )

        // Then
        XCTAssertEqual(group.id, 123)
    }
}

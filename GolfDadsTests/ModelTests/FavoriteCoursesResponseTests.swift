//
//  FavoriteCoursesResponseTests.swift
//  GolfDadsTests
//
//  Tests for FavoriteCoursesResponse model decoding from API
//

import XCTest
@testable import GolfDads

final class FavoriteCoursesResponseTests: XCTestCase {

    // MARK: - Decoding Tests

    func testDecodeFavoriteCoursesResponseFromJSON() throws {
        // Given - Response with snake_case keys from API
        let json = """
        {
            "golf_courses": [
                {
                    "id": 1,
                    "external_id": 101,
                    "name": "Pebble Beach Golf Links",
                    "club_name": "Pebble Beach Resorts",
                    "address": "1700 17 Mile Drive",
                    "city": "Pebble Beach",
                    "state": "CA",
                    "zip_code": "93953",
                    "country": "United States",
                    "latitude": 36.5674,
                    "longitude": -121.9487,
                    "phone": "831-624-3811",
                    "website": "https://www.pebblebeach.com",
                    "distance_miles": 2.5,
                    "is_favorite": true
                },
                {
                    "id": 2,
                    "external_id": 102,
                    "name": "Torrey Pines",
                    "club_name": "Torrey Pines Golf Course",
                    "address": "11480 N Torrey Pines Rd",
                    "city": "La Jolla",
                    "state": "CA",
                    "zip_code": "92037",
                    "country": "United States",
                    "latitude": 32.9230,
                    "longitude": -117.2527,
                    "phone": "858-452-3226",
                    "website": "https://www.sandiego.gov/torreypines",
                    "distance_miles": 125.3,
                    "is_favorite": true
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Custom date decoder (matching NetworkService)
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: dateString) {
                return date
            }
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }

        // When
        let response = try decoder.decode(FavoriteCoursesResponse.self, from: json)

        // Then
        XCTAssertEqual(response.golfCourses.count, 2)

        // Verify first course
        let firstCourse = response.golfCourses[0]
        XCTAssertEqual(firstCourse.id, 1)
        XCTAssertEqual(firstCourse.externalId, 101)
        XCTAssertEqual(firstCourse.name, "Pebble Beach Golf Links")
        XCTAssertEqual(firstCourse.clubName, "Pebble Beach Resorts")
        XCTAssertEqual(firstCourse.address, "1700 17 Mile Drive")
        XCTAssertEqual(firstCourse.city, "Pebble Beach")
        XCTAssertEqual(firstCourse.state, "CA")
        XCTAssertEqual(firstCourse.zipCode, "93953")
        XCTAssertEqual(firstCourse.country, "United States")
        XCTAssertEqual(firstCourse.latitude, 36.5674)
        XCTAssertEqual(firstCourse.longitude, -121.9487)
        XCTAssertEqual(firstCourse.phone, "831-624-3811")
        XCTAssertEqual(firstCourse.website, "https://www.pebblebeach.com")
        XCTAssertEqual(firstCourse.distanceMiles, 2.5)
        XCTAssertEqual(firstCourse.isFavorite, true)

        // Verify second course
        let secondCourse = response.golfCourses[1]
        XCTAssertEqual(secondCourse.id, 2)
        XCTAssertEqual(secondCourse.name, "Torrey Pines")
        XCTAssertEqual(secondCourse.isFavorite, true)
    }

    func testDecodeEmptyFavoriteCoursesResponse() throws {
        // Given - Empty response (what the user saw in the error log)
        let json = """
        {
            "golf_courses": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // When
        let response = try decoder.decode(FavoriteCoursesResponse.self, from: json)

        // Then
        XCTAssertTrue(response.golfCourses.isEmpty)
    }

    func testDecodeFavoriteCourseResponse() throws {
        // Given - Single course response (for add/remove operations)
        let json = """
        {
            "golf_course": {
                "id": 1,
                "external_id": 101,
                "name": "Pebble Beach Golf Links",
                "club_name": "Pebble Beach Resorts",
                "address": "1700 17 Mile Drive",
                "city": "Pebble Beach",
                "state": "CA",
                "zip_code": "93953",
                "country": "United States",
                "latitude": 36.5674,
                "longitude": -121.9487,
                "phone": "831-624-3811",
                "website": "https://www.pebblebeach.com",
                "is_favorite": true
            },
            "message": "Course added to favorites"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // When
        let response = try decoder.decode(FavoriteCourseResponse.self, from: json)

        // Then
        XCTAssertEqual(response.golfCourse.id, 1)
        XCTAssertEqual(response.golfCourse.name, "Pebble Beach Golf Links")
        XCTAssertEqual(response.golfCourse.isFavorite, true)
        XCTAssertEqual(response.message, "Course added to favorites")
    }

    func testDecodeGolfCourseWithMinimalFields() throws {
        // Given - Response with only required fields
        let json = """
        {
            "golf_courses": [
                {
                    "id": null,
                    "external_id": null,
                    "name": "Basic Course",
                    "club_name": null,
                    "address": null,
                    "city": null,
                    "state": null,
                    "zip_code": null,
                    "country": null,
                    "latitude": null,
                    "longitude": null,
                    "phone": null,
                    "website": null,
                    "distance_miles": null,
                    "is_favorite": null
                }
            ]
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // When
        let response = try decoder.decode(FavoriteCoursesResponse.self, from: json)

        // Then
        XCTAssertEqual(response.golfCourses.count, 1)
        let course = response.golfCourses[0]
        XCTAssertNil(course.id)
        XCTAssertNil(course.externalId)
        XCTAssertEqual(course.name, "Basic Course")
        XCTAssertNil(course.clubName)
        XCTAssertNil(course.address)
        XCTAssertNil(course.city)
        XCTAssertNil(course.state)
        XCTAssertNil(course.zipCode)
        XCTAssertNil(course.country)
        XCTAssertNil(course.latitude)
        XCTAssertNil(course.longitude)
        XCTAssertNil(course.phone)
        XCTAssertNil(course.website)
        XCTAssertNil(course.distanceMiles)
        XCTAssertNil(course.isFavorite)
    }

    // MARK: - Error Case Tests

    func testDecodeFailsWithoutSnakeCaseConversion() {
        // Given - Response with snake_case keys but no decoder strategy
        let json = """
        {
            "golf_courses": []
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        // NOT setting keyDecodingStrategy

        // When/Then - This should fail because decoder expects camelCase
        XCTAssertThrowsError(try decoder.decode(FavoriteCoursesResponse.self, from: json)) { error in
            // Verify it's the expected decoding error
            guard case DecodingError.keyNotFound(let key, _) = error else {
                XCTFail("Expected keyNotFound error, got \(error)")
                return
            }
            XCTAssertEqual(key.stringValue, "golfCourses")
        }
    }
}

//
//  TeeTimeService.swift
//  GolfDads
//
//  Service for managing tee time postings
//

import Foundation

protocol TeeTimeServiceProtocol {
    func getTeeTimePostings() async throws -> [TeeTimePosting]
    func getNearbyTeeTimePostings(latitude: Double, longitude: Double, radius: Int) async throws -> [TeeTimePosting]
    func getTeeTimePosting(id: Int) async throws -> TeeTimePosting
    func getMyTeeTimePostings() async throws -> [TeeTimePosting]
    func getGroupTeeTimePostings(groupId: Int) async throws -> [TeeTimePosting]
    func createTeeTimePosting(
        courseName: String,
        teeTime: Date,
        totalSpots: Int,
        initialReservationSpots: Int?,
        notes: String?,
        groupIds: [Int],
        golfCourseId: Int?
    ) async throws -> TeeTimePosting
    func updateTeeTimePosting(id: Int, availableSpots: Int) async throws -> TeeTimePosting
    func deleteTeeTimePosting(id: Int) async throws
}

class TeeTimeService: TeeTimeServiceProtocol {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// Fetch all public tee time postings
    func getTeeTimePostings() async throws -> [TeeTimePosting] {
        struct Response: Codable {
            let teeTimePostings: [TeeTimePosting]
        }

        let response: Response = try await networkService.request(
            endpoint: .teeTimePostings,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.teeTimePostings
    }

    /// Fetch nearby tee time postings based on location
    func getNearbyTeeTimePostings(latitude: Double, longitude: Double, radius: Int) async throws -> [TeeTimePosting] {
        struct Response: Codable {
            let teeTimePostings: [TeeTimePosting]
        }

        let response: Response = try await networkService.request(
            endpoint: .teeTimePostingsWithLocation(latitude: latitude, longitude: longitude, radius: radius),
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.teeTimePostings
    }

    /// Fetch a specific tee time posting by ID
    func getTeeTimePosting(id: Int) async throws -> TeeTimePosting {
        struct Response: Codable {
            let teeTimePosting: TeeTimePosting
        }

        let response: Response = try await networkService.request(
            endpoint: .teeTimePosting(id: id),
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.teeTimePosting
    }

    /// Fetch current user's tee time postings
    /// Note: The Rails API doesn't have a dedicated endpoint for user's postings,
    /// so we fetch all postings and filter by user_id client-side
    func getMyTeeTimePostings() async throws -> [TeeTimePosting] {
        // Get the current user's ID from keychain
        let keychainService = KeychainService()
        guard let token = keychainService.getToken() else {
            throw APIError.unauthorized(message: "No authentication token found")
        }

        // Decode JWT to get user_id (basic JWT decode without verification)
        let parts = token.components(separatedBy: ".")
        guard parts.count == 3,
              let payloadData = Data(base64Encoded: parts[1].base64PaddedString()),
              let payload = try? JSONSerialization.jsonObject(with: payloadData) as? [String: Any],
              let userId = payload["user_id"] as? Int else {
            throw APIError.unauthorized(message: "Invalid authentication token")
        }

        // Fetch all tee time postings and filter by current user
        let allPostings = try await getTeeTimePostings()
        return allPostings.filter { $0.userId == userId }
    }

    /// Fetch tee time postings for a specific group
    func getGroupTeeTimePostings(groupId: Int) async throws -> [TeeTimePosting] {
        struct Response: Codable {
            let teeTimePostings: [TeeTimePosting]
        }

        let response: Response = try await networkService.request(
            endpoint: .groupTeeTimePostings(groupId: groupId),
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.teeTimePostings
    }

    /// Create a new tee time posting
    func createTeeTimePosting(
        courseName: String,
        teeTime: Date,
        totalSpots: Int,
        initialReservationSpots: Int? = nil,
        notes: String? = nil,
        groupIds: [Int] = [],
        golfCourseId: Int? = nil
    ) async throws -> TeeTimePosting {
        struct TeeTimePostingRequest: Encodable {
            let teeTimePosting: TeeTimePostingData
            let initialReservationSpots: Int?

            struct TeeTimePostingData: Encodable {
                let courseName: String
                let teeTime: Date
                let totalSpots: Int
                let notes: String?
                let groupIds: [Int]
                let golfCourseId: Int?
            }
        }

        let body = TeeTimePostingRequest(
            teeTimePosting: .init(
                courseName: courseName,
                teeTime: teeTime,
                totalSpots: totalSpots,
                notes: notes,
                groupIds: groupIds,
                golfCourseId: golfCourseId
            ),
            initialReservationSpots: initialReservationSpots
        )

        struct Response: Codable {
            let teeTimePosting: TeeTimePosting
        }

        let response: Response = try await networkService.request(
            endpoint: .teeTimePostings,
            method: .post,
            body: body,
            requiresAuth: true
        )

        return response.teeTimePosting
    }

    /// Update available spots for a tee time posting
    func updateTeeTimePosting(id: Int, availableSpots: Int) async throws -> TeeTimePosting {
        struct UpdateRequest: Encodable {
            let teeTimePosting: UpdateData

            struct UpdateData: Encodable {
                let availableSpots: Int
            }
        }

        let body = UpdateRequest(
            teeTimePosting: .init(availableSpots: availableSpots)
        )

        struct Response: Codable {
            let teeTimePosting: TeeTimePosting
        }

        let response: Response = try await networkService.request(
            endpoint: .teeTimePosting(id: id),
            method: .patch,
            body: body,
            requiresAuth: true
        )

        return response.teeTimePosting
    }

    /// Delete a tee time posting
    func deleteTeeTimePosting(id: Int) async throws {
        let _: EmptyResponse = try await networkService.request(
            endpoint: .teeTimePosting(id: id),
            method: .delete,
            body: nil as String?,
            requiresAuth: true
        )
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Codable {}

// MARK: - Base64 Helper

private extension String {
    /// Adds padding to base64url string to make it valid base64
    func base64PaddedString() -> String {
        var base64 = self
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")

        let remainder = base64.count % 4
        if remainder > 0 {
            base64 = base64.padding(toLength: base64.count + 4 - remainder,
                                    withPad: "=",
                                    startingAt: 0)
        }
        return base64
    }
}

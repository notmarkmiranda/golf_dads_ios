//
//  TeeTimeService.swift
//  GolfDads
//
//  Service for managing tee time postings
//

import Foundation

protocol TeeTimeServiceProtocol {
    func getTeeTimePostings() async throws -> [TeeTimePosting]
    func getTeeTimePosting(id: Int) async throws -> TeeTimePosting
    func getMyTeeTimePostings() async throws -> [TeeTimePosting]
    func getGroupTeeTimePostings(groupId: Int) async throws -> [TeeTimePosting]
    func createTeeTimePosting(
        courseName: String,
        teeTime: Date,
        availableSpots: Int,
        totalSpots: Int?,
        notes: String?,
        groupId: Int?
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
        return try await networkService.request(
            endpoint: .teeTimePostings,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )
    }

    /// Fetch a specific tee time posting by ID
    func getTeeTimePosting(id: Int) async throws -> TeeTimePosting {
        return try await networkService.request(
            endpoint: .teeTimePosting(id: id),
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )
    }

    /// Fetch current user's tee time postings
    func getMyTeeTimePostings() async throws -> [TeeTimePosting] {
        return try await networkService.request(
            endpoint: .myTeeTimePostings,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )
    }

    /// Fetch tee time postings for a specific group
    func getGroupTeeTimePostings(groupId: Int) async throws -> [TeeTimePosting] {
        return try await networkService.request(
            endpoint: .groupTeeTimePostings(groupId: groupId),
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )
    }

    /// Create a new tee time posting
    func createTeeTimePosting(
        courseName: String,
        teeTime: Date,
        availableSpots: Int,
        totalSpots: Int? = nil,
        notes: String? = nil,
        groupId: Int? = nil
    ) async throws -> TeeTimePosting {
        struct TeeTimePostingRequest: Encodable {
            let teeTimePosting: TeeTimePostingData

            struct TeeTimePostingData: Encodable {
                let courseName: String
                let teeTime: Date
                let availableSpots: Int
                let totalSpots: Int?
                let notes: String?
                let groupId: Int?
            }
        }

        let body = TeeTimePostingRequest(
            teeTimePosting: .init(
                courseName: courseName,
                teeTime: teeTime,
                availableSpots: availableSpots,
                totalSpots: totalSpots,
                notes: notes,
                groupId: groupId
            )
        )

        return try await networkService.request(
            endpoint: .teeTimePostings,
            method: .post,
            body: body,
            requiresAuth: true
        )
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

        return try await networkService.request(
            endpoint: .teeTimePosting(id: id),
            method: .patch,
            body: body,
            requiresAuth: true
        )
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

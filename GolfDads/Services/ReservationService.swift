//
//  ReservationService.swift
//  GolfDads
//
//  Service for managing reservations
//

import Foundation

protocol ReservationServiceProtocol {
    func getReservations() async throws -> [Reservation]
    func getReservation(id: Int) async throws -> Reservation
    func getMyReservations() async throws -> [Reservation]
    func createReservation(teeTimePostingId: Int, spotsReserved: Int) async throws -> Reservation
    func updateReservation(id: Int, spotsReserved: Int) async throws -> Reservation
    func deleteReservation(id: Int) async throws
}

class ReservationService: ReservationServiceProtocol {

    private let networkService: NetworkServiceProtocol

    init(networkService: NetworkServiceProtocol = NetworkService()) {
        self.networkService = networkService
    }

    // MARK: - Public Methods

    /// Fetch all reservations
    func getReservations() async throws -> [Reservation] {
        struct Response: Codable {
            let reservations: [Reservation]
        }

        let response: Response = try await networkService.request(
            endpoint: .reservations,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.reservations
    }

    /// Fetch a specific reservation by ID
    func getReservation(id: Int) async throws -> Reservation {
        struct Response: Codable {
            let reservation: Reservation
        }

        let response: Response = try await networkService.request(
            endpoint: .reservation(id: id),
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.reservation
    }

    /// Fetch current user's reservations
    func getMyReservations() async throws -> [Reservation] {
        struct Response: Codable {
            let reservations: [Reservation]
        }

        let response: Response = try await networkService.request(
            endpoint: .myReservations,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.reservations
    }

    /// Create a new reservation
    func createReservation(
        teeTimePostingId: Int,
        spotsReserved: Int
    ) async throws -> Reservation {
        struct ReservationRequest: Encodable {
            let reservation: ReservationData

            struct ReservationData: Encodable {
                let teeTimePostingId: Int
                let spotsReserved: Int
            }
        }

        let body = ReservationRequest(
            reservation: .init(
                teeTimePostingId: teeTimePostingId,
                spotsReserved: spotsReserved
            )
        )

        struct Response: Codable {
            let reservation: Reservation
        }

        let response: Response = try await networkService.request(
            endpoint: .reservations,
            method: .post,
            body: body,
            requiresAuth: true
        )

        return response.reservation
    }

    /// Update a reservation
    func updateReservation(id: Int, spotsReserved: Int) async throws -> Reservation {
        struct UpdateRequest: Encodable {
            let reservation: UpdateData

            struct UpdateData: Encodable {
                let spotsReserved: Int
            }
        }

        let body = UpdateRequest(
            reservation: .init(spotsReserved: spotsReserved)
        )

        struct Response: Codable {
            let reservation: Reservation
        }

        let response: Response = try await networkService.request(
            endpoint: .reservation(id: id),
            method: .patch,
            body: body,
            requiresAuth: true
        )

        return response.reservation
    }

    /// Delete a reservation
    func deleteReservation(id: Int) async throws {
        let _: EmptyResponse = try await networkService.request(
            endpoint: .reservation(id: id),
            method: .delete,
            body: nil as String?,
            requiresAuth: true
        )
    }
}

// MARK: - Empty Response

private struct EmptyResponse: Codable {}

//
//  MockNetworkService.swift
//  GolfDadsTests
//

import Foundation
@testable import GolfDads

/// Mock network service for testing
class MockNetworkService: NetworkServiceProtocol {

    // MARK: - Mock Configuration

    /// Response to return for requests
    var mockResponse: Any?

    /// Error to throw instead of returning response
    var mockError: Error?

    /// Track the last request made
    var lastEndpoint: APIConfiguration.Endpoint?
    var lastMethod: HTTPMethod?
    var lastBody: Encodable?
    var lastRequiresAuth: Bool?

    /// Track all requests made
    var requestHistory: [(endpoint: APIConfiguration.Endpoint, method: HTTPMethod)] = []

    // MARK: - NetworkServiceProtocol Implementation

    func request<T: Decodable>(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) async throws -> T {
        // Track request
        lastEndpoint = endpoint
        lastMethod = method
        lastBody = body
        lastRequiresAuth = requiresAuth
        requestHistory.append((endpoint: endpoint, method: method))

        // Throw error if configured
        if let error = mockError {
            throw error
        }

        // Return mock response
        guard let response = mockResponse as? T else {
            throw APIError.missingData
        }

        return response
    }

    func request(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) async throws {
        // Track request
        lastEndpoint = endpoint
        lastMethod = method
        lastBody = body
        lastRequiresAuth = requiresAuth
        requestHistory.append((endpoint: endpoint, method: method))

        // Throw error if configured
        if let error = mockError {
            throw error
        }

        // No response needed for this method
    }

    // MARK: - Test Helpers

    /// Reset all tracking
    func reset() {
        mockResponse = nil
        mockError = nil
        lastEndpoint = nil
        lastMethod = nil
        lastBody = nil
        lastRequiresAuth = nil
        requestHistory.removeAll()
    }

    /// Check if a specific endpoint was called
    func wasCalled(endpoint: APIConfiguration.Endpoint) -> Bool {
        return requestHistory.contains { $0.endpoint.path == endpoint.path }
    }

    /// Get the number of times an endpoint was called
    func callCount(for endpoint: APIConfiguration.Endpoint) -> Int {
        return requestHistory.filter { $0.endpoint.path == endpoint.path }.count
    }
}

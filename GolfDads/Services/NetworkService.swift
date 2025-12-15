//
//  NetworkService.swift
//  GolfDads
//

import Foundation

/// Protocol for URLSession to enable mocking
protocol URLSessionProtocol {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

/// Make URLSession conform to our protocol
extension URLSession: URLSessionProtocol {}

/// Protocol for network operations (enables mocking for tests)
protocol NetworkServiceProtocol {
    func request<T: Decodable>(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) async throws -> T

    func request(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) async throws
}

/// HTTP methods supported by the network service
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

/// Network service for making HTTP requests to the API
class NetworkService: NetworkServiceProtocol {

    // MARK: - Singleton

    static let shared = NetworkService()

    // MARK: - Properties

    private let session: URLSessionProtocol
    private let keychainService: KeychainServiceProtocol
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    // MARK: - Initialization

    init(
        session: URLSessionProtocol = URLSession.shared,
        keychainService: KeychainServiceProtocol = KeychainService()
    ) {
        self.session = session
        self.keychainService = keychainService

        // Configure decoder for API date formats
        self.decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        // Custom date decoder to handle both ISO8601 with and without fractional seconds
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)

            // Try with fractional seconds first
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            // Try without fractional seconds
            dateFormatter.formatOptions = [.withInternetDateTime]
            if let date = dateFormatter.date(from: dateString) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(dateString)"
            )
        }

        // Configure encoder for API
        self.encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
    }

    // MARK: - Public Methods

    /// Make a network request that expects a decoded response
    func request<T: Decodable>(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        let data = try await performRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("❌ Decoding error for \(endpoint.path):")
            print("   Error: \(error)")
            if let dataString = String(data: data, encoding: .utf8) {
                print("   Response: \(dataString)")
            }
            throw APIError.decodingError(error: error)
        }
    }

    /// Make a network request that doesn't expect a response body (e.g., DELETE)
    func request(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod = .get,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        _ = try await performRequest(
            endpoint: endpoint,
            method: method,
            body: body,
            requiresAuth: requiresAuth
        )
    }

    // MARK: - Private Methods

    private func performRequest(
        endpoint: APIConfiguration.Endpoint,
        method: HTTPMethod,
        body: Encodable?,
        requiresAuth: Bool
    ) async throws -> Data {
        // Build URL
        guard let url = URL(string: endpoint.fullURL) else {
            throw APIError.invalidURL
        }

        // Build request
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = APIConfiguration.timeout

        // Add headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Add authorization header if required
        if requiresAuth {
            guard let token = keychainService.getToken() else {
                throw APIError.missingToken
            }
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Add body if provided
        if let body = body {
            do {
                request.httpBody = try encoder.encode(AnyEncodable(body))
            } catch {
                throw APIError.encodingError(error: error)
            }
        }

        // Log request (in debug mode)
        #if DEBUG
        logRequest(request, body: body)
        #endif

        // Perform request
        let (data, response) = try await performWithErrorHandling(request: request)

        // Log response (in debug mode)
        #if DEBUG
        logResponse(response, data: data)
        #endif

        // Validate response
        try validateResponse(response, data: data)

        return data
    }

    private func performWithErrorHandling(request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            throw APIError.from(urlError: urlError)
        } catch {
            throw APIError.unknown(error: error)
        }
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        // 2xx status codes are success
        guard (200...299).contains(httpResponse.statusCode) else {
            let error = APIError.from(statusCode: httpResponse.statusCode, data: data)

            // Post notification if unauthorized (token expired)
            if case .unauthorized = error {
                NotificationCenter.default.post(name: .unauthorizedErrorOccurred, object: nil)
            }

            throw error
        }
    }

    // MARK: - Logging

    private func logRequest(_ request: URLRequest, body: Encodable?) {
        print("🌐 Network Request")
        print("   Method: \(request.httpMethod ?? "UNKNOWN")")
        print("   URL: \(request.url?.absoluteString ?? "INVALID")")

        if let headers = request.allHTTPHeaderFields {
            print("   Headers:")
            for (key, value) in headers {
                // Don't log full auth token for security
                if key == "Authorization" {
                    print("      \(key): Bearer ***")
                } else {
                    print("      \(key): \(value)")
                }
            }
        }

        if let body = body {
            if let jsonData = try? encoder.encode(AnyEncodable(body)),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                print("   Body: \(jsonString)")
            }
        }
    }

    private func logResponse(_ response: URLResponse, data: Data) {
        guard let httpResponse = response as? HTTPURLResponse else { return }

        print("📥 Network Response")
        print("   Status: \(httpResponse.statusCode)")

        if let dataString = String(data: data, encoding: .utf8) {
            print("   Body: \(dataString.prefix(500))") // Limit output
        }
    }
}

// MARK: - Helper for Encoding Any Type

/// Wrapper to encode any Encodable type
private struct AnyEncodable: Encodable {
    private let encode: (Encoder) throws -> Void

    init<T: Encodable>(_ wrapped: T) {
        encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try encode(encoder)
    }
}

// MARK: - Convenience Extensions

extension NetworkServiceProtocol {

    // GET with response
    func get<T: Decodable>(
        endpoint: APIConfiguration.Endpoint,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .get,
            body: nil as String?,
            requiresAuth: requiresAuth
        )
    }

    // POST with response
    func post<T: Decodable>(
        endpoint: APIConfiguration.Endpoint,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .post,
            body: body,
            requiresAuth: requiresAuth
        )
    }

    // POST without response
    func post(
        endpoint: APIConfiguration.Endpoint,
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws {
        try await request(
            endpoint: endpoint,
            method: .post,
            body: body,
            requiresAuth: requiresAuth
        )
    }

    // PATCH with response
    func patch<T: Decodable>(
        endpoint: APIConfiguration.Endpoint,
        body: Encodable,
        requiresAuth: Bool = true
    ) async throws -> T {
        try await request(
            endpoint: endpoint,
            method: .patch,
            body: body,
            requiresAuth: requiresAuth
        )
    }

    // DELETE without response
    func delete(
        endpoint: APIConfiguration.Endpoint,
        requiresAuth: Bool = true
    ) async throws {
        try await request(
            endpoint: endpoint,
            method: .delete,
            body: nil as String?,
            requiresAuth: requiresAuth
        )
    }
}

// MARK: - Notification API Methods

extension NetworkService {

    /// Register device token for push notifications
    func registerDeviceToken(token: String, platform: String) async throws {
        struct DeviceTokenRequest: Codable {
            let deviceToken: DeviceTokenData

            struct DeviceTokenData: Codable {
                let token: String
                let platform: String
            }
        }

        let request = DeviceTokenRequest(
            deviceToken: DeviceTokenRequest.DeviceTokenData(token: token, platform: platform)
        )

        try await self.request(
            endpoint: .deviceTokens,
            method: .post,
            body: request,
            requiresAuth: true
        )
    }

    /// Unregister device token
    func unregisterDeviceToken(token: String) async throws {
        try await self.request(
            endpoint: .deviceToken(token: token),
            method: .delete,
            body: nil as String?,
            requiresAuth: true
        )
    }

    /// Get user's notification preferences
    func getNotificationPreferences() async throws -> NotificationPreferences {
        let response: NotificationPreferencesResponse = try await self.request(
            endpoint: .notificationPreferences,
            method: .get,
            body: nil as String?,
            requiresAuth: true
        )

        return response.notificationPreferences ?? NotificationPreferences.defaultPreferences
    }

    /// Update user's notification preferences
    func updateNotificationPreferences(_ update: NotificationPreferencesUpdate) async throws -> NotificationPreferences {
        let request = NotificationPreferencesUpdateRequest(
            notificationPreferences: update
        )

        let response: NotificationPreferencesResponse = try await self.request(
            endpoint: .notificationPreferences,
            method: .patch,
            body: request,
            requiresAuth: true
        )

        return response.notificationPreferences ?? NotificationPreferences.defaultPreferences
    }

    /// Update notification settings for a specific group (mute/unmute)
    func updateGroupNotificationSettings(groupId: Int, muted: Bool) async throws {
        struct GroupNotificationSettingsRequest: Codable {
            let notificationSettings: NotificationSettingsData

            struct NotificationSettingsData: Codable {
                let muted: Bool
            }
        }

        let request = GroupNotificationSettingsRequest(
            notificationSettings: GroupNotificationSettingsRequest.NotificationSettingsData(muted: muted)
        )

        try await self.request(
            endpoint: .groupNotificationSettings(groupId: groupId),
            method: .patch,
            body: request,
            requiresAuth: true
        )
    }
}

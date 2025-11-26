//
//  APIError.swift
//  GolfDads
//

import Foundation

/// Comprehensive error handling for API requests
enum APIError: LocalizedError {

    // MARK: - Network Errors

    /// No internet connection available
    case noInternetConnection

    /// Request timed out
    case timeout

    /// Network connection was lost during request
    case connectionLost

    /// Cannot connect to host
    case cannotConnectToHost

    // MARK: - HTTP Errors

    /// Invalid response from server (not HTTP)
    case invalidResponse

    /// Bad request (400)
    case badRequest(message: String?)

    /// Unauthorized (401) - invalid or expired token
    case unauthorized(message: String?)

    /// Forbidden (403) - valid token but insufficient permissions
    case forbidden(message: String?)

    /// Not found (404)
    case notFound(message: String?)

    /// Unprocessable entity (422) - validation errors
    case validationError(errors: [String: [String]])

    /// Generic server error (500+)
    case serverError(statusCode: Int, message: String?)

    /// Unexpected HTTP status code
    case unexpectedStatusCode(statusCode: Int)

    // MARK: - Data Errors

    /// Failed to decode response data
    case decodingError(error: Error)

    /// Failed to encode request data
    case encodingError(error: Error)

    /// Response data is missing
    case missingData

    // MARK: - Authentication Errors

    /// Google Sign-In failed
    case googleSignInFailed(reason: String)

    /// Missing or invalid JWT token
    case missingToken

    /// Token refresh failed
    case tokenRefreshFailed

    // MARK: - Configuration Errors

    /// Invalid URL construction
    case invalidURL

    /// Missing configuration (API URL, Client ID, etc.)
    case missingConfiguration(key: String)

    // MARK: - Unknown

    /// Unknown error with underlying error
    case unknown(error: Error?)

    // MARK: - Error Descriptions

    var errorDescription: String? {
        switch self {
        // Network Errors
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
        case .timeout:
            return "The request timed out. Please try again."
        case .connectionLost:
            return "Network connection was lost. Please try again."
        case .cannotConnectToHost:
            return "Cannot connect to server. Please check your connection."

        // HTTP Errors
        case .invalidResponse:
            return "Invalid response from server."
        case .badRequest(let message):
            return message ?? "Bad request. Please check your input."
        case .unauthorized(let message):
            return message ?? "Unauthorized. Please log in again."
        case .forbidden(let message):
            return message ?? "You don't have permission to perform this action."
        case .notFound(let message):
            return message ?? "The requested resource was not found."
        case .validationError(let errors):
            return formatValidationErrors(errors)
        case .serverError(_, let message):
            return message ?? "Server error. Please try again later."
        case .unexpectedStatusCode(let code):
            return "Unexpected response from server (status: \(code))."

        // Data Errors
        case .decodingError:
            return "Failed to process server response."
        case .encodingError:
            return "Failed to prepare request data."
        case .missingData:
            return "Server response is missing data."

        // Authentication Errors
        case .googleSignInFailed(let reason):
            return "Google Sign-In failed: \(reason)"
        case .missingToken:
            return "Authentication token is missing. Please log in."
        case .tokenRefreshFailed:
            return "Failed to refresh authentication. Please log in again."

        // Configuration Errors
        case .invalidURL:
            return "Invalid request URL."
        case .missingConfiguration(let key):
            return "Missing configuration: \(key)"

        // Unknown
        case .unknown(let error):
            if let error = error {
                return "An unexpected error occurred: \(error.localizedDescription)"
            }
            return "An unexpected error occurred."
        }
    }

    // MARK: - User-Friendly Messages

    /// Short, user-friendly message suitable for alerts
    var userMessage: String {
        switch self {
        case .noInternetConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .unauthorized(let message):
            return message ?? "Please log in again"
        case .forbidden:
            return "Permission denied"
        case .notFound:
            return "Not found"
        case .validationError(let errors):
            if let firstField = errors.keys.first,
               let firstErrorArray = errors[firstField],
               let firstError = firstErrorArray.first {
                return "\(firstField): \(firstError)"
            }
            return "Please check your input"
        case .serverError(_, let message):
            return message ?? "Server error"
        default:
            return "Something went wrong"
        }
    }

    // MARK: - Helpers

    /// Check if error requires re-authentication
    var requiresReauthentication: Bool {
        switch self {
        case .unauthorized, .missingToken, .tokenRefreshFailed:
            return true
        default:
            return false
        }
    }

    /// Check if error is retryable
    var isRetryable: Bool {
        switch self {
        case .timeout, .connectionLost, .cannotConnectToHost, .serverError:
            return true
        case .noInternetConnection:
            return false // User needs to fix connection first
        default:
            return false
        }
    }

    // MARK: - Private Helpers

    private func formatValidationErrors(_ errors: [String: [String]]) -> String {
        var messages: [String] = []
        for (field, fieldErrors) in errors {
            let fieldName = field.replacingOccurrences(of: "_", with: " ").capitalized
            for error in fieldErrors {
                messages.append("\(fieldName): \(error)")
            }
        }
        return messages.isEmpty ? "Validation failed" : messages.joined(separator: "\n")
    }
}

// MARK: - Factory Methods

extension APIError {

    /// Create APIError from URLError
    static func from(urlError: URLError) -> APIError {
        switch urlError.code {
        case .notConnectedToInternet, .dataNotAllowed, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        case .cannotConnectToHost, .cannotFindHost:
            return .cannotConnectToHost
        default:
            return .unknown(error: urlError)
        }
    }

    /// Create APIError from HTTP response
    static func from(statusCode: Int, data: Data?) -> APIError {
        // Try to parse error message from response
        var message: String?
        var validationErrors: [String: [String]]?

        if let data = data {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                message = json["error"] as? String
                validationErrors = json["errors"] as? [String: [String]]
            }
        }

        switch statusCode {
        case 400:
            return .badRequest(message: message)
        case 401:
            return .unauthorized(message: message)
        case 403:
            return .forbidden(message: message)
        case 404:
            return .notFound(message: message)
        case 422:
            if let errors = validationErrors {
                return .validationError(errors: errors)
            }
            return .badRequest(message: message ?? "Validation failed")
        case 500...599:
            return .serverError(statusCode: statusCode, message: message)
        default:
            return .unexpectedStatusCode(statusCode: statusCode)
        }
    }
}

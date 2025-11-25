//
//  APIConfiguration.swift
//  GolfDads
//

import Foundation

/// Configuration for API endpoints and environment settings
struct APIConfiguration {

    // MARK: - Environment

    /// Current environment (Debug or Release)
    static var environment: Environment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    enum Environment {
        case development
        case production

        var name: String {
            switch self {
            case .development: return "Development"
            case .production: return "Production"
            }
        }
    }

    // MARK: - API Configuration

    /// Base URL for API requests
    /// Reads from Info.plist or falls back to defaults
    static var baseURL: String {
        // Try to read from Info.plist first
        if let url = Bundle.main.object(forInfoDictionaryKey: "API_BASE_URL") as? String,
           !url.isEmpty,
           url != "$(API_BASE_URL)" { // Not a placeholder
            return url
        }

        // Fall back to environment-specific defaults
        return environment.defaultBaseURL
    }

    /// Google OAuth Client ID
    /// Reads from Info.plist or falls back to empty (will fail auth if not configured)
    static var googleClientID: String {
        // Try to read from Info.plist first
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String,
           !clientID.isEmpty,
           clientID != "$(GOOGLE_CLIENT_ID)" { // Not a placeholder
            return clientID
        }

        // Return empty string if not configured (will need to be set)
        print("⚠️ WARNING: GOOGLE_CLIENT_ID not configured in Info.plist")
        return ""
    }

    // MARK: - API Endpoints

    enum Endpoint {
        // Authentication
        case signup
        case login
        case googleSignIn
        case currentUser

        // Users
        case users
        case user(id: Int)

        // Groups
        case groups
        case group(id: Int)
        case groupMembers(groupId: Int)
        case joinGroup(groupId: Int)
        case leaveGroup(groupId: Int)

        // Tee Time Postings
        case teeTimePostings
        case teeTimePosting(id: Int)
        case myTeeTimePostings
        case groupTeeTimePostings(groupId: Int)

        // Reservations
        case reservations
        case reservation(id: Int)
        case myReservations

        var path: String {
            switch self {
            // Authentication
            case .signup: return "/v1/auth/signup"
            case .login: return "/v1/auth/login"
            case .googleSignIn: return "/v1/auth/google"
            case .currentUser: return "/v1/users/current"

            // Users
            case .users: return "/v1/users"
            case .user(let id): return "/v1/users/\(id)"

            // Groups
            case .groups: return "/v1/groups"
            case .group(let id): return "/v1/groups/\(id)"
            case .groupMembers(let groupId): return "/v1/groups/\(groupId)/members"
            case .joinGroup(let groupId): return "/v1/groups/\(groupId)/join"
            case .leaveGroup(let groupId): return "/v1/groups/\(groupId)/leave"

            // Tee Time Postings
            case .teeTimePostings: return "/v1/tee_time_postings"
            case .teeTimePosting(let id): return "/v1/tee_time_postings/\(id)"
            case .myTeeTimePostings: return "/v1/tee_time_postings/my_postings"
            case .groupTeeTimePostings(let groupId): return "/v1/groups/\(groupId)/tee_time_postings"

            // Reservations
            case .reservations: return "/v1/reservations"
            case .reservation(let id): return "/v1/reservations/\(id)"
            case .myReservations: return "/v1/reservations/my_reservations"
            }
        }

        var fullURL: String {
            return APIConfiguration.baseURL + path
        }
    }

    // MARK: - Timeout Configuration

    /// Default timeout for API requests (in seconds)
    static let timeout: TimeInterval = 30

    // MARK: - Debugging

    /// Print current configuration (useful for debugging)
    static func printConfiguration() {
        print("🔧 API Configuration")
        print("   Environment: \(environment.name)")
        print("   Base URL: \(baseURL)")
        print("   Google Client ID: \(googleClientID.isEmpty ? "⚠️ Not configured" : "✅ Configured")")
        print("   Timeout: \(timeout)s")
    }
}

// MARK: - Private Helpers

private extension APIConfiguration.Environment {
    var defaultBaseURL: String {
        switch self {
        case .development:
            // For iOS Simulator, localhost works
            // For physical device testing, use your Mac's IP address
            #if targetEnvironment(simulator)
            return "http://localhost:3000/api"
            #else
            // Use ngrok or your Mac's local IP for device testing
            return "http://192.168.1.100:3000/api" // Change to your Mac's IP
            #endif
        case .production:
            // Update this with your production API URL
            return "https://your-production-api.onrender.com/api"
        }
    }
}

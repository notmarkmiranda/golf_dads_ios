//
//  AuthenticationService.swift
//  GolfDads
//

import Foundation

/// Authentication response from the API
struct AuthenticationResponse: Codable {
    let token: String
    let user: AuthenticatedUser
}

/// User data returned from authentication
struct AuthenticatedUser: Codable {
    let id: Int
    let email: String
    let name: String
    let avatarUrl: String?
    let provider: String?
    let venmoHandle: String?
    let handicap: Double?

    // Custom decoding key mapping
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case avatarUrl = "avatar_url"
        case provider
        case venmoHandle = "venmo_handle"
        case handicap
    }

    // Regular init for creating instances
    init(id: Int, email: String, name: String, avatarUrl: String?, provider: String?, venmoHandle: String?, handicap: Double?) {
        self.id = id
        self.email = email
        self.name = name
        self.avatarUrl = avatarUrl
        self.provider = provider
        self.venmoHandle = venmoHandle
        self.handicap = handicap
    }

    // Custom decoder to handle handicap as either string or number
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decode(Int.self, forKey: .id)
        email = try container.decode(String.self, forKey: .email)
        name = try container.decode(String.self, forKey: .name)
        avatarUrl = try container.decodeIfPresent(String.self, forKey: .avatarUrl)
        provider = try container.decodeIfPresent(String.self, forKey: .provider)

        // Try to decode venmo_handle (using the CodingKey mapping)
        venmoHandle = try container.decodeIfPresent(String.self, forKey: .venmoHandle)

        print("🔍 Decoding user: \(email)")
        print("   Raw keys: \(container.allKeys)")
        print("   venmoHandle: \(venmoHandle ?? "nil")")

        // Handle handicap as either Double or String (Rails returns it as string)
        if let handicapDouble = try? container.decodeIfPresent(Double.self, forKey: .handicap) {
            handicap = handicapDouble
            print("   handicap (as Double): \(handicapDouble)")
        } else if let handicapString = try? container.decodeIfPresent(String.self, forKey: .handicap) {
            handicap = Double(handicapString)
            print("   handicap (from String): \(String(describing: handicap))")
        } else {
            handicap = nil
            print("   handicap: nil")
        }
    }

    // Custom encoder to maintain proper key mapping
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(email, forKey: .email)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(avatarUrl, forKey: .avatarUrl)
        try container.encodeIfPresent(provider, forKey: .provider)
        try container.encodeIfPresent(venmoHandle, forKey: .venmoHandle)
        try container.encodeIfPresent(handicap, forKey: .handicap)
    }
}

/// Protocol for authentication operations
protocol AuthenticationServiceProtocol {
    func signUp(email: String, password: String, name: String) async throws -> AuthenticationResponse
    func login(email: String, password: String) async throws -> AuthenticationResponse
    func googleSignIn(idToken: String) async throws -> AuthenticationResponse
    func getCurrentUser() async throws -> AuthenticatedUser
    func logout() throws

    var isLoggedIn: Bool { get }
    var currentToken: String? { get }
}

/// Service for handling user authentication
class AuthenticationService: AuthenticationServiceProtocol {

    // MARK: - Properties

    private let networkService: NetworkServiceProtocol
    private let keychainService: KeychainServiceProtocol

    // MARK: - Initialization

    init(
        networkService: NetworkServiceProtocol = NetworkService(),
        keychainService: KeychainServiceProtocol = KeychainService()
    ) {
        self.networkService = networkService
        self.keychainService = keychainService
    }

    // MARK: - Sign Up

    /// Sign up a new user with email and password
    func signUp(email: String, password: String, name: String) async throws -> AuthenticationResponse {
        struct UserParams: Encodable {
            let email: String
            let password: String
            let passwordConfirmation: String
            let name: String
        }

        struct SignUpRequest: Encodable {
            let user: UserParams
        }

        let request = SignUpRequest(
            user: UserParams(
                email: email,
                password: password,
                passwordConfirmation: password,
                name: name
            )
        )

        let response: AuthenticationResponse = try await networkService.post(
            endpoint: .signup,
            body: request,
            requiresAuth: false
        )

        // Save token to keychain
        try keychainService.saveToken(response.token)

        return response
    }

    // MARK: - Login

    /// Log in an existing user with email and password
    func login(email: String, password: String) async throws -> AuthenticationResponse {
        struct LoginRequest: Encodable {
            let email: String
            let password: String
        }

        let request = LoginRequest(
            email: email,
            password: password
        )

        let response: AuthenticationResponse = try await networkService.post(
            endpoint: .login,
            body: request,
            requiresAuth: false
        )

        // Save token to keychain
        try keychainService.saveToken(response.token)

        return response
    }

    // MARK: - Google Sign-In

    /// Sign in with Google using an ID token
    func googleSignIn(idToken: String) async throws -> AuthenticationResponse {
        struct GoogleSignInRequest: Encodable {
            let idToken: String
        }

        let request = GoogleSignInRequest(idToken: idToken)

        let response: AuthenticationResponse = try await networkService.post(
            endpoint: .googleSignIn,
            body: request,
            requiresAuth: false
        )

        // Save token to keychain
        try keychainService.saveToken(response.token)

        return response
    }

    // MARK: - Get Current User

    /// Get the currently authenticated user's information
    func getCurrentUser() async throws -> AuthenticatedUser {
        let response: AuthenticatedUser = try await networkService.get(
            endpoint: .currentUser,
            requiresAuth: true
        )

        return response
    }

    // MARK: - Logout

    /// Log out the current user (clears stored token)
    func logout() throws {
        try keychainService.deleteToken()
        try? keychainService.deleteRefreshToken() // Best effort
    }

    // MARK: - Helper Properties

    /// Check if a user is currently logged in (has a token)
    var isLoggedIn: Bool {
        return keychainService.hasToken
    }

    /// Get the stored JWT token
    var currentToken: String? {
        return keychainService.getToken()
    }
}

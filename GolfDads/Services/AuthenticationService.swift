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

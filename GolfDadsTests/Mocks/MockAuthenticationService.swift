//
//  MockAuthenticationService.swift
//  GolfDadsTests
//

import Foundation
@testable import GolfDads

class MockAuthenticationService: AuthenticationServiceProtocol {

    // MARK: - Mock Properties

    var mockResponse: AuthenticationResponse?
    var mockUser: AuthenticatedUser?
    var mockError: Error?
    var mockIsLoggedIn: Bool = false
    var mockCurrentToken: String?

    // MARK: - Call Tracking

    var signUpCalled = false
    var loginCalled = false
    var googleSignInCalled = false
    var getCurrentUserCalled = false
    var logoutCalled = false

    var lastSignUpEmail: String?
    var lastSignUpPassword: String?
    var lastSignUpName: String?

    var lastLoginEmail: String?
    var lastLoginPassword: String?

    var lastGoogleIdToken: String?

    // MARK: - AuthenticationServiceProtocol

    func signUp(email: String, password: String, name: String) async throws -> AuthenticationResponse {
        signUpCalled = true
        lastSignUpEmail = email
        lastSignUpPassword = password
        lastSignUpName = name

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse else {
            throw APIError.serverError(statusCode: 500, message: "No mock response configured")
        }

        return response
    }

    func login(email: String, password: String) async throws -> AuthenticationResponse {
        loginCalled = true
        lastLoginEmail = email
        lastLoginPassword = password

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse else {
            throw APIError.serverError(statusCode: 500, message: "No mock response configured")
        }

        return response
    }

    func googleSignIn(idToken: String) async throws -> AuthenticationResponse {
        googleSignInCalled = true
        lastGoogleIdToken = idToken

        if let error = mockError {
            throw error
        }

        guard let response = mockResponse else {
            throw APIError.serverError(statusCode: 500, message: "No mock response configured")
        }

        return response
    }

    func getCurrentUser() async throws -> AuthenticatedUser {
        getCurrentUserCalled = true

        if let error = mockError {
            throw error
        }

        guard let user = mockUser else {
            throw APIError.serverError(statusCode: 500, message: "No mock user configured")
        }

        return user
    }

    func logout() throws {
        logoutCalled = true

        if let error = mockError {
            throw error
        }
    }

    var isLoggedIn: Bool {
        return mockIsLoggedIn
    }

    var currentToken: String? {
        return mockCurrentToken
    }

    // MARK: - Helper Methods

    func reset() {
        mockResponse = nil
        mockUser = nil
        mockError = nil
        mockIsLoggedIn = false
        mockCurrentToken = nil

        signUpCalled = false
        loginCalled = false
        googleSignInCalled = false
        getCurrentUserCalled = false
        logoutCalled = false

        lastSignUpEmail = nil
        lastSignUpPassword = nil
        lastSignUpName = nil
        lastLoginEmail = nil
        lastLoginPassword = nil
        lastGoogleIdToken = nil
    }
}

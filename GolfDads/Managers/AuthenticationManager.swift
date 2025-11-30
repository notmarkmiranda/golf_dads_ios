//
//  AuthenticationManager.swift
//  GolfDads
//
//  Manages authentication state and user session
//

import Foundation
import Observation

/// Manager for handling authentication state and operations
/// Uses @Observable for SwiftUI reactive updates
@Observable
@MainActor
class AuthenticationManager {

    // MARK: - Published Properties

    /// Current authenticated user
    private(set) var currentUser: AuthenticatedUser?

    /// Whether the user is authenticated
    private(set) var isAuthenticated: Bool = false

    /// Loading state for async operations
    private(set) var isLoading: Bool = false

    /// Error message to display to user
    private(set) var errorMessage: String?

    // MARK: - Private Properties

    private let authService: AuthenticationServiceProtocol
    private nonisolated(unsafe) var unauthorizedObserver: NSObjectProtocol?

    // MARK: - Initialization

    init(authService: AuthenticationServiceProtocol = AuthenticationService()) {
        self.authService = authService
        self.isAuthenticated = authService.isLoggedIn

        // Listen for unauthorized errors (expired JWT)
        unauthorizedObserver = NotificationCenter.default.addObserver(
            forName: .unauthorizedErrorOccurred,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.handleUnauthorizedError()
            }
        }
    }

    deinit {
        if let observer = unauthorizedObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Sign Up

    /// Sign up a new user with email and password
    func signUp(email: String, password: String, name: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.signUp(email: email, password: password, name: name)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = handleError(error)
            isAuthenticated = false
            currentUser = nil
        }

        isLoading = false
    }

    // MARK: - Login

    /// Log in an existing user with email and password
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.login(email: email, password: password)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = handleError(error)
            isAuthenticated = false
            currentUser = nil
        }

        isLoading = false
    }

    // MARK: - Google Sign-In

    /// Sign in with Google using an ID token
    func googleSignIn(idToken: String) async {
        isLoading = true
        errorMessage = nil

        do {
            let response = try await authService.googleSignIn(idToken: idToken)
            currentUser = response.user
            isAuthenticated = true
        } catch {
            errorMessage = handleError(error)
            isAuthenticated = false
            currentUser = nil
        }

        isLoading = false
    }

    // MARK: - Logout

    /// Log out the current user
    func logout() async {
        do {
            try authService.logout()
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch {
            errorMessage = handleError(error)
            // Even if logout fails on server, clear local state
            currentUser = nil
            isAuthenticated = false
        }
    }

    // MARK: - Refresh Current User

    /// Refresh the current user's information from the server
    func refreshCurrentUser() async {
        guard authService.isLoggedIn else {
            return
        }

        do {
            let user = try await authService.getCurrentUser()
            currentUser = user
        } catch {
            errorMessage = handleError(error)
            // If refresh fails due to auth error, log out
            if case APIError.unauthorized = error {
                currentUser = nil
                isAuthenticated = false
            }
        }
    }

    // MARK: - Check Auth Status

    /// Check if user is currently authenticated (has valid token)
    func checkAuthStatus() {
        isAuthenticated = authService.isLoggedIn
    }

    // MARK: - Clear Error

    /// Clear the current error message
    func clearError() {
        errorMessage = nil
    }

    // MARK: - Private Helpers

    /// Handle unauthorized errors by automatically logging out
    private func handleUnauthorizedError() async {
        print("🔒 JWT token expired - logging out automatically")
        await logout()
    }

    /// Convert errors to user-friendly messages
    private func handleError(_ error: Error) -> String {
        if let apiError = error as? APIError {
            return apiError.userMessage
        }
        return error.localizedDescription
    }
}

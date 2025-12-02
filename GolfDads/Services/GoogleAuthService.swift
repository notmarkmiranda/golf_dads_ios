//
//  GoogleAuthService.swift
//  GolfDads
//
//  Handles Google Sign-In authentication flow
//

import Foundation
import GoogleSignIn

/// Protocol for Google authentication operations
protocol GoogleAuthServiceProtocol {
    func signIn() async throws -> String
    func signOut()
}

/// Service for handling Google Sign-In authentication
final class GoogleAuthService: GoogleAuthServiceProtocol {

    private let clientID: String

    init(clientID: String = APIConfiguration.shared.googleClientID) {
        self.clientID = clientID
    }

    /// Initiates Google Sign-In flow and returns the ID token
    /// - Returns: Google ID token string
    /// - Throws: APIError if sign-in fails
    func signIn() async throws -> String {
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = await windowScene.windows.first?.rootViewController else {
            throw APIError.custom(message: "Unable to find root view controller")
        }

        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(
                withPresenting: rootViewController
            )

            guard let idToken = result.user.idToken?.tokenString else {
                throw APIError.custom(message: "Failed to get ID token from Google")
            }

            return idToken
        } catch {
            // Map Google Sign-In errors to our APIError
            if let gidError = error as? GIDSignInError {
                switch gidError.code {
                case .canceled:
                    throw APIError.custom(message: "Sign in canceled")
                case .hasNoAuthInKeychain:
                    throw APIError.custom(message: "No auth in keychain")
                default:
                    throw APIError.custom(message: "Google Sign-In failed: \(gidError.localizedDescription)")
                }
            }

            throw APIError.custom(message: "Google Sign-In failed: \(error.localizedDescription)")
        }
    }

    /// Signs out from Google
    func signOut() {
        GIDSignIn.sharedInstance.signOut()
    }
}

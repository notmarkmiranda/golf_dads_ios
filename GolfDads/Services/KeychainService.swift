//
//  KeychainService.swift
//  GolfDads
//

import Foundation
import KeychainAccess

/// Protocol for keychain operations (enables mocking for tests)
protocol KeychainServiceProtocol {
    func saveToken(_ token: String) throws
    func getToken() -> String?
    func deleteToken() throws
    func saveRefreshToken(_ token: String) throws
    func getRefreshToken() -> String?
    func deleteRefreshToken() throws
    func clearAll() throws
    var hasToken: Bool { get }
    var hasRefreshToken: Bool { get }
}

/// Service for securely storing authentication tokens in the keychain
class KeychainService: KeychainServiceProtocol {

    // MARK: - Properties

    private let keychain: Keychain
    private let tokenKey = "jwt_token"
    private let refreshTokenKey = "refresh_token"

    // MARK: - Initialization

    init(service: String = "com.golfdads.GolfDads") {
        self.keychain = Keychain(service: service)
            .synchronizable(false) // Don't sync to iCloud for security
            .accessibility(.whenUnlockedThisDeviceOnly) // Only accessible when device is unlocked
    }

    // MARK: - JWT Token

    /// Save JWT access token to keychain
    /// - Parameter token: The JWT token string
    /// - Throws: KeychainError if save fails
    func saveToken(_ token: String) throws {
        try keychain.set(token, key: tokenKey)
    }

    /// Retrieve JWT access token from keychain
    /// - Returns: The stored token, or nil if not found
    func getToken() -> String? {
        return try? keychain.get(tokenKey)
    }

    /// Delete JWT access token from keychain
    /// - Throws: KeychainError if deletion fails
    func deleteToken() throws {
        try keychain.remove(tokenKey)
    }

    // MARK: - Refresh Token

    /// Save refresh token to keychain
    /// - Parameter token: The refresh token string
    /// - Throws: KeychainError if save fails
    func saveRefreshToken(_ token: String) throws {
        try keychain.set(token, key: refreshTokenKey)
    }

    /// Retrieve refresh token from keychain
    /// - Returns: The stored refresh token, or nil if not found
    func getRefreshToken() -> String? {
        return try? keychain.get(refreshTokenKey)
    }

    /// Delete refresh token from keychain
    /// - Throws: KeychainError if deletion fails
    func deleteRefreshToken() throws {
        try keychain.remove(refreshTokenKey)
    }

    // MARK: - Helpers

    /// Clear all tokens from keychain
    /// - Throws: KeychainError if clear fails
    func clearAll() throws {
        try keychain.removeAll()
    }

    /// Check if a valid token exists
    var hasToken: Bool {
        return getToken() != nil
    }

    /// Check if a valid refresh token exists
    var hasRefreshToken: Bool {
        return getRefreshToken() != nil
    }
}

// MARK: - Mock Implementation for Testing

/// Mock keychain service for testing (stores tokens in memory)
class MockKeychainService: KeychainServiceProtocol {

    // In-memory storage for testing
    private var tokens: [String: String] = [:]
    private let tokenKey = "jwt_token"
    private let refreshTokenKey = "refresh_token"

    // Flags for testing error scenarios
    var shouldThrowOnSave = false
    var shouldThrowOnDelete = false

    func saveToken(_ token: String) throws {
        if shouldThrowOnSave {
            throw NSError(domain: "MockKeychainError", code: -1, userInfo: nil)
        }
        tokens[tokenKey] = token
    }

    func getToken() -> String? {
        return tokens[tokenKey]
    }

    func deleteToken() throws {
        if shouldThrowOnDelete {
            throw NSError(domain: "MockKeychainError", code: -1, userInfo: nil)
        }
        tokens.removeValue(forKey: tokenKey)
    }

    func saveRefreshToken(_ token: String) throws {
        if shouldThrowOnSave {
            throw NSError(domain: "MockKeychainError", code: -1, userInfo: nil)
        }
        tokens[refreshTokenKey] = token
    }

    func getRefreshToken() -> String? {
        return tokens[refreshTokenKey]
    }

    func deleteRefreshToken() throws {
        if shouldThrowOnDelete {
            throw NSError(domain: "MockKeychainError", code: -1, userInfo: nil)
        }
        tokens.removeValue(forKey: refreshTokenKey)
    }

    func clearAll() throws {
        if shouldThrowOnDelete {
            throw NSError(domain: "MockKeychainError", code: -1, userInfo: nil)
        }
        tokens.removeAll()
    }

    var hasToken: Bool {
        return getToken() != nil
    }

    var hasRefreshToken: Bool {
        return getRefreshToken() != nil
    }
}

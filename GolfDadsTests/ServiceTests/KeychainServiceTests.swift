//
//  KeychainServiceTests.swift
//  GolfDadsTests
//

import XCTest
@testable import GolfDads

final class KeychainServiceTests: XCTestCase {

    var sut: MockKeychainService!

    override func setUp() {
        super.setUp()
        sut = MockKeychainService()
    }

    override func tearDown() {
        try? sut.clearAll()
        sut = nil
        super.tearDown()
    }

    // MARK: - JWT Token Tests

    func testSaveAndRetrieveToken() throws {
        // Given
        let token = "test_jwt_token_12345"

        // When
        try sut.saveToken(token)
        let retrievedToken = sut.getToken()

        // Then
        XCTAssertEqual(retrievedToken, token)
    }

    func testGetTokenReturnsNilWhenNoTokenStored() {
        // When
        let token = sut.getToken()

        // Then
        XCTAssertNil(token)
    }

    func testDeleteToken() throws {
        // Given
        try sut.saveToken("test_token")

        // When
        try sut.deleteToken()
        let token = sut.getToken()

        // Then
        XCTAssertNil(token)
    }

    func testHasTokenReturnsTrueWhenTokenExists() throws {
        // Given
        try sut.saveToken("test_token")

        // When/Then
        XCTAssertTrue(sut.hasToken)
    }

    func testHasTokenReturnsFalseWhenNoToken() {
        // When/Then
        XCTAssertFalse(sut.hasToken)
    }

    // MARK: - Refresh Token Tests

    func testSaveAndRetrieveRefreshToken() throws {
        // Given
        let refreshToken = "test_refresh_token_67890"

        // When
        try sut.saveRefreshToken(refreshToken)
        let retrievedToken = sut.getRefreshToken()

        // Then
        XCTAssertEqual(retrievedToken, refreshToken)
    }

    func testGetRefreshTokenReturnsNilWhenNoTokenStored() {
        // When
        let token = sut.getRefreshToken()

        // Then
        XCTAssertNil(token)
    }

    func testDeleteRefreshToken() throws {
        // Given
        try sut.saveRefreshToken("test_refresh_token")

        // When
        try sut.deleteRefreshToken()
        let token = sut.getRefreshToken()

        // Then
        XCTAssertNil(token)
    }

    func testHasRefreshTokenReturnsTrueWhenTokenExists() throws {
        // Given
        try sut.saveRefreshToken("test_refresh_token")

        // When/Then
        XCTAssertTrue(sut.hasRefreshToken)
    }

    func testHasRefreshTokenReturnsFalseWhenNoToken() {
        // When/Then
        XCTAssertFalse(sut.hasRefreshToken)
    }

    // MARK: - Clear All Tests

    func testClearAllRemovesAllTokens() throws {
        // Given
        try sut.saveToken("access_token")
        try sut.saveRefreshToken("refresh_token")

        // When
        try sut.clearAll()

        // Then
        XCTAssertNil(sut.getToken())
        XCTAssertNil(sut.getRefreshToken())
        XCTAssertFalse(sut.hasToken)
        XCTAssertFalse(sut.hasRefreshToken)
    }

    // MARK: - Error Handling Tests

    func testSaveTokenThrowsErrorWhenConfigured() {
        // Given
        sut.shouldThrowOnSave = true

        // When/Then
        XCTAssertThrowsError(try sut.saveToken("test_token"))
    }

    func testDeleteTokenThrowsErrorWhenConfigured() throws {
        // Given
        try sut.saveToken("test_token")
        sut.shouldThrowOnDelete = true

        // When/Then
        XCTAssertThrowsError(try sut.deleteToken())
    }

    func testClearAllThrowsErrorWhenConfigured() throws {
        // Given
        try sut.saveToken("test_token")
        sut.shouldThrowOnDelete = true

        // When/Then
        XCTAssertThrowsError(try sut.clearAll())
    }

    // MARK: - Token Independence Tests

    func testAccessAndRefreshTokensAreIndependent() throws {
        // Given
        let accessToken = "access_token_123"
        let refreshToken = "refresh_token_456"

        // When
        try sut.saveToken(accessToken)
        try sut.saveRefreshToken(refreshToken)

        // Then
        XCTAssertEqual(sut.getToken(), accessToken)
        XCTAssertEqual(sut.getRefreshToken(), refreshToken)

        // When - delete access token
        try sut.deleteToken()

        // Then - refresh token should still exist
        XCTAssertNil(sut.getToken())
        XCTAssertEqual(sut.getRefreshToken(), refreshToken)
    }

    func testOverwritingToken() throws {
        // Given
        try sut.saveToken("old_token")

        // When
        try sut.saveToken("new_token")

        // Then
        XCTAssertEqual(sut.getToken(), "new_token")
    }
}

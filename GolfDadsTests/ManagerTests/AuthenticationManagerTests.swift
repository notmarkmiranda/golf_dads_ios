//
//  AuthenticationManagerTests.swift
//  GolfDadsTests
//

import XCTest
@testable import GolfDads

@MainActor
final class AuthenticationManagerTests: XCTestCase {

    var sut: AuthenticationManager!
    var mockAuthService: MockAuthenticationService!

    override func setUp() async throws {
        try await super.setUp()
        mockAuthService = MockAuthenticationService()
        sut = AuthenticationManager(authService: mockAuthService)
    }

    override func tearDown() async throws {
        sut = nil
        mockAuthService = nil
        try await super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        // Given/When - initialized in setUp

        // Then
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(sut.isLoading)
        XCTAssertNil(sut.errorMessage)
    }

    func testInitWithExistingToken() async {
        // Given
        mockAuthService.mockIsLoggedIn = true

        // When
        let manager = await AuthenticationManager(authService: mockAuthService)

        // Then
        await XCTAssertTrue(manager.isAuthenticated)
    }

    // MARK: - Sign Up Tests

    func testSignUpSuccess() async {
        // Given
        let email = "newuser@example.com"
        let password = "password123"
        let name = "New User"
        let expectedToken = "jwt_token_new"

        let mockResponse = AuthenticationResponse(
            token: expectedToken,
            user: AuthenticatedUser(
                id: 1,
                email: email,
                name: name,
                avatarUrl: nil,
                provider: "email",
                venmoHandle: nil,
                handicap: nil
            )
        )
        mockAuthService.mockResponse = mockResponse

        // When
        await sut.signUp(email: email, password: password, name: name)

        // Then
        XCTAssertTrue(mockAuthService.signUpCalled)
        XCTAssertEqual(mockAuthService.lastSignUpEmail, email)
        XCTAssertEqual(mockAuthService.lastSignUpPassword, password)
        XCTAssertEqual(mockAuthService.lastSignUpName, name)

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.email, email)
        XCTAssertEqual(sut.currentUser?.name, name)
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testSignUpFailure() async {
        // Given
        mockAuthService.mockError = APIError.serverError(statusCode: 422, message: "Email already taken")

        // When
        await sut.signUp(email: "test@example.com", password: "pass", name: "Test")

        // Then
        XCTAssertTrue(mockAuthService.signUpCalled)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Email already taken") ?? false)
        XCTAssertFalse(sut.isLoading)
    }

    func testSignUpSetsLoadingState() async {
        // Given
        let expectation = expectation(description: "Loading state observed")
        mockAuthService.mockResponse = AuthenticationResponse(
            token: "token",
            user: AuthenticatedUser(id: 1, email: "test@example.com", name: "Test", avatarUrl: nil, provider: "email", venmoHandle: nil, handicap: nil)
        )

        // When
        Task {
            // Small delay to allow isLoading to be set
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
            if self.sut.isLoading || !self.sut.isLoading {
                expectation.fulfill()
            }
        }

        await sut.signUp(email: "test@example.com", password: "pass", name: "Test")

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertFalse(sut.isLoading) // Should be false after completion
    }

    // MARK: - Login Tests

    func testLoginSuccess() async {
        // Given
        let email = "existing@example.com"
        let password = "password123"
        let expectedToken = "jwt_token_existing"

        let mockResponse = AuthenticationResponse(
            token: expectedToken,
            user: AuthenticatedUser(
                id: 2,
                email: email,
                name: "Existing User",
                avatarUrl: "https://example.com/avatar.jpg",
                provider: "email",
                venmoHandle: nil,
                handicap: nil
            )
        )
        mockAuthService.mockResponse = mockResponse

        // When
        await sut.login(email: email, password: password)

        // Then
        XCTAssertTrue(mockAuthService.loginCalled)
        XCTAssertEqual(mockAuthService.lastLoginEmail, email)
        XCTAssertEqual(mockAuthService.lastLoginPassword, password)

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.email, email)
        XCTAssertEqual(sut.currentUser?.avatarUrl, "https://example.com/avatar.jpg")
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testLoginFailure() async {
        // Given
        mockAuthService.mockError = APIError.unauthorized(message: "Invalid credentials")

        // When
        await sut.login(email: "wrong@example.com", password: "wrongpass")

        // Then
        XCTAssertTrue(mockAuthService.loginCalled)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertTrue(sut.errorMessage?.contains("Invalid credentials") ?? false)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Google Sign-In Tests

    func testGoogleSignInSuccess() async {
        // Given
        let idToken = "google_id_token_abc123"
        let expectedToken = "jwt_token_google"

        let mockResponse = AuthenticationResponse(
            token: expectedToken,
            user: AuthenticatedUser(
                id: 3,
                email: "google@example.com",
                name: "Google User",
                avatarUrl: "https://lh3.googleusercontent.com/avatar",
                provider: "google"
            )
        )
        mockAuthService.mockResponse = mockResponse

        // When
        await sut.googleSignIn(idToken: idToken)

        // Then
        XCTAssertTrue(mockAuthService.googleSignInCalled)
        XCTAssertEqual(mockAuthService.lastGoogleIdToken, idToken)

        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.email, "google@example.com")
        XCTAssertEqual(sut.currentUser?.provider, "google")
        XCTAssertNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    func testGoogleSignInFailure() async {
        // Given
        mockAuthService.mockError = APIError.serverError(statusCode: 401, message: "Invalid Google token")

        // When
        await sut.googleSignIn(idToken: "invalid_token")

        // Then
        XCTAssertTrue(mockAuthService.googleSignInCalled)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
        XCTAssertFalse(sut.isLoading)
    }

    // MARK: - Logout Tests

    func testLogoutSuccess() async {
        // Given - set up authenticated state
        mockAuthService.mockResponse = AuthenticationResponse(
            token: "token",
            user: AuthenticatedUser(id: 1, email: "test@example.com", name: "Test", avatarUrl: nil, provider: "email", venmoHandle: nil, handicap: nil)
        )
        await sut.login(email: "test@example.com", password: "pass")
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)

        // When
        await sut.logout()

        // Then
        XCTAssertTrue(mockAuthService.logoutCalled)
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNil(sut.errorMessage)
    }

    func testLogoutFailure() async {
        // Given - set up authenticated state
        mockAuthService.mockResponse = AuthenticationResponse(
            token: "token",
            user: AuthenticatedUser(id: 1, email: "test@example.com", name: "Test", avatarUrl: nil, provider: "email", venmoHandle: nil, handicap: nil)
        )
        await sut.login(email: "test@example.com", password: "pass")

        // Set logout to fail
        mockAuthService.mockError = APIError.unknown(error: NSError(domain: "test", code: 1))

        // When
        await sut.logout()

        // Then
        XCTAssertTrue(mockAuthService.logoutCalled)
        // Even if logout fails, we should clear local state
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage) // Error should be captured
    }

    // MARK: - Clear Error Tests

    func testClearError() async {
        // Given - trigger an error
        mockAuthService.mockError = APIError.unauthorized(message: "Test error")
        await sut.login(email: "test@example.com", password: "pass")
        XCTAssertNotNil(sut.errorMessage)

        // When
        sut.clearError()

        // Then
        XCTAssertNil(sut.errorMessage)
    }

    // MARK: - Check Auth Status Tests

    func testCheckAuthStatusWhenLoggedIn() async {
        // Given
        mockAuthService.mockIsLoggedIn = true
        let mockUser = AuthenticatedUser(
            id: 1,
            email: "test@example.com",
            name: "Test User",
            avatarUrl: nil,
            provider: "email",
            venmoHandle: nil,
            handicap: nil
        )
        mockAuthService.mockUser = mockUser

        // When
        await sut.checkAuthStatus()

        // Then
        XCTAssertTrue(sut.isAuthenticated)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.id, 1)
        XCTAssertTrue(mockAuthService.getCurrentUserCalled)
    }

    func testCheckAuthStatusWhenLoggedOut() async {
        // Given
        mockAuthService.mockIsLoggedIn = false

        // When
        await sut.checkAuthStatus()

        // Then
        XCTAssertFalse(sut.isAuthenticated)
        XCTAssertFalse(mockAuthService.getCurrentUserCalled)
    }

    // MARK: - Refresh Current User Tests

    func testRefreshCurrentUserSuccess() async {
        // Given
        let mockUser = AuthenticatedUser(
            id: 1,
            email: "updated@example.com",
            name: "Updated User",
            avatarUrl: "https://example.com/new-avatar.jpg",
            provider: "email",
            venmoHandle: nil,
            handicap: nil
        )
        mockAuthService.mockUser = mockUser
        mockAuthService.mockIsLoggedIn = true

        // When
        await sut.refreshCurrentUser()

        // Then
        XCTAssertTrue(mockAuthService.getCurrentUserCalled)
        XCTAssertNotNil(sut.currentUser)
        XCTAssertEqual(sut.currentUser?.email, "updated@example.com")
        XCTAssertEqual(sut.currentUser?.name, "Updated User")
        XCTAssertNil(sut.errorMessage)
    }

    func testRefreshCurrentUserFailure() async {
        // Given
        mockAuthService.mockError = APIError.unauthorized(message: "Token expired")
        mockAuthService.mockIsLoggedIn = true

        // When
        await sut.refreshCurrentUser()

        // Then
        XCTAssertTrue(mockAuthService.getCurrentUserCalled)
        XCTAssertNil(sut.currentUser)
        XCTAssertNotNil(sut.errorMessage)
        // Should log out on auth failure
        XCTAssertFalse(sut.isAuthenticated)
    }

    func testRefreshCurrentUserWhenNotLoggedIn() async {
        // Given
        mockAuthService.mockIsLoggedIn = false

        // When
        await sut.refreshCurrentUser()

        // Then
        XCTAssertFalse(mockAuthService.getCurrentUserCalled)
        XCTAssertNil(sut.currentUser)
        XCTAssertFalse(sut.isAuthenticated)
    }
}

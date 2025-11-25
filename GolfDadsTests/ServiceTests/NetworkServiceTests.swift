//
//  NetworkServiceTests.swift
//  GolfDadsTests
//

import XCTest
@testable import GolfDads

final class NetworkServiceTests: XCTestCase {

    var sut: NetworkService!
    var mockKeychain: MockKeychainService!
    var mockSession: MockURLSession!

    override func setUp() {
        super.setUp()
        mockKeychain = MockKeychainService()
        mockSession = MockURLSession()
        sut = NetworkService(session: mockSession, keychainService: mockKeychain)
    }

    override func tearDown() {
        sut = nil
        mockKeychain = nil
        mockSession = nil
        super.tearDown()
    }

    // MARK: - Authentication Tests

    func testRequestIncludesAuthorizationHeaderWhenTokenExists() async throws {
        // Given
        let token = "test_jwt_token"
        try mockKeychain.saveToken(token)

        let mockData = """
        {"id": 1, "name": "Test"}
        """.data(using: .utf8)!
        mockSession.mockData = mockData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let _: TestModel = try await sut.get(endpoint: .users)

        // Then
        XCTAssertNotNil(mockSession.lastRequest)
        let authHeader = mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer \(token)")
    }

    func testRequestThrowsMissingTokenErrorWhenAuthRequiredButNoToken() async {
        // Given
        // No token in keychain

        // When/Then
        do {
            let _: TestModel = try await sut.get(endpoint: .users, requiresAuth: true)
            XCTFail("Should have thrown missing token error")
        } catch let error as APIError {
            if case .missingToken = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func testRequestDoesNotIncludeAuthHeaderWhenAuthNotRequired() async throws {
        // Given
        let mockData = """
        {"id": 1, "name": "Test"}
        """.data(using: .utf8)!
        mockSession.mockData = mockData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let _: TestModel = try await sut.get(endpoint: .users, requiresAuth: false)

        // Then
        let authHeader = mockSession.lastRequest?.value(forHTTPHeaderField: "Authorization")
        XCTAssertNil(authHeader)
    }

    // MARK: - HTTP Method Tests

    func testGetRequestSetsCorrectHTTPMethod() async throws {
        // Given
        try mockKeychain.saveToken("token")
        setupSuccessResponse()

        // When
        let _: TestModel = try await sut.get(endpoint: .users)

        // Then
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "GET")
    }

    func testPostRequestSetsCorrectHTTPMethod() async throws {
        // Given
        try mockKeychain.saveToken("token")
        setupSuccessResponse()

        // When
        let _: TestModel = try await sut.post(endpoint: .users, body: TestModel(id: 1, name: "Test"))

        // Then
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "POST")
    }

    func testPatchRequestSetsCorrectHTTPMethod() async throws {
        // Given
        try mockKeychain.saveToken("token")
        setupSuccessResponse()

        // When
        let _: TestModel = try await sut.patch(
            endpoint: .user(id: 1),
            body: TestModel(id: 1, name: "Updated")
        )

        // Then
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "PATCH")
    }

    func testDeleteRequestSetsCorrectHTTPMethod() async throws {
        // Given
        try mockKeychain.saveToken("token")
        setupSuccessResponse(withData: Data()) // DELETE may have empty response

        // When
        try await sut.delete(endpoint: .user(id: 1))

        // Then
        XCTAssertEqual(mockSession.lastRequest?.httpMethod, "DELETE")
    }

    // MARK: - Response Handling Tests

    func testSuccessfulRequestDecodesResponse() async throws {
        // Given
        try mockKeychain.saveToken("token")
        let expectedModel = TestModel(id: 42, name: "Test User")
        let mockData = """
        {"id": 42, "name": "Test User"}
        """.data(using: .utf8)!
        mockSession.mockData = mockData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When
        let result: TestModel = try await sut.get(endpoint: .users)

        // Then
        XCTAssertEqual(result.id, expectedModel.id)
        XCTAssertEqual(result.name, expectedModel.name)
    }

    func testInvalidJSONThrowsDecodingError() async {
        // Given
        try? mockKeychain.saveToken("token")
        let invalidJSON = "{ invalid json }".data(using: .utf8)!
        mockSession.mockData = invalidJSON
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            let _: TestModel = try await sut.get(endpoint: .users)
            XCTFail("Should have thrown decoding error")
        } catch let error as APIError {
            if case .decodingError = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Error Handling Tests

    func test401ResponseThrowsUnauthorizedError() async {
        // Given
        try? mockKeychain.saveToken("token")
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            let _: TestModel = try await sut.get(endpoint: .users)
            XCTFail("Should have thrown unauthorized error")
        } catch let error as APIError {
            if case .unauthorized = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func test404ResponseThrowsNotFoundError() async {
        // Given
        try? mockKeychain.saveToken("token")
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 404,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            let _: TestModel = try await sut.get(endpoint: .user(id: 999))
            XCTFail("Should have thrown not found error")
        } catch let error as APIError {
            if case .notFound = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    func test500ResponseThrowsServerError() async {
        // Given
        try? mockKeychain.saveToken("token")
        mockSession.mockData = Data()
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 500,
            httpVersion: nil,
            headerFields: nil
        )

        // When/Then
        do {
            let _: TestModel = try await sut.get(endpoint: .users)
            XCTFail("Should have thrown server error")
        } catch let error as APIError {
            if case .serverError = error {
                // Success
            } else {
                XCTFail("Wrong error type: \(error)")
            }
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func setupSuccessResponse(withData data: Data? = nil) {
        let responseData = data ?? """
        {"id": 1, "name": "Test"}
        """.data(using: .utf8)!

        mockSession.mockData = responseData
        mockSession.mockResponse = HTTPURLResponse(
            url: URL(string: "http://test.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )
    }
}

// MARK: - Test Models

private struct TestModel: Codable, Equatable {
    let id: Int
    let name: String
}

// MARK: - Mock URLSession

class MockURLSession: URLSessionProtocol {
    var mockData: Data?
    var mockResponse: URLResponse?
    var mockError: Error?
    var lastRequest: URLRequest?

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request

        if let error = mockError {
            throw error
        }

        guard let data = mockData, let response = mockResponse else {
            throw URLError(.badServerResponse)
        }

        return (data, response)
    }
}

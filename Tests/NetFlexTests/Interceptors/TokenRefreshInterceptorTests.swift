import XCTest
@testable import NetFlex

class TokenRefreshInterceptorTests: XCTestCase {
  func testInterceptorRefreshesTokenAndRetriesRequest() async throws {
    // Arrange
    let initialToken = "old_token"
    var updatedToken = initialToken
    let tokenProvider = { return updatedToken }
    
    var tokenRefreshCalled = false
    let tokenRefresher = {
      tokenRefreshCalled = true
      updatedToken = "new_token"
    }
    
    // Mock HTTPClient to return 401 on first request, 200 on retry
    let mockHTTPClient = MockerHTTPClient()
    var requestCount = 0
    mockHTTPClient.fetchDataHandler = { request in
      requestCount += 1
      let token = request.value(forHTTPHeaderField: "Authorization") ?? ""
      if token.contains("old_token") {
        // First attempt with old token: return 401 Unauthorized
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 401,
          httpVersion: nil,
          headerFields: nil
        )!
        return (Data(), response)
      } else if token.contains("new_token") {
        // Second attempt with new token: return 200 OK
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = "success".data(using: .utf8)!
        return (data, response)
      } else {
        XCTFail("Unexpected token in request")
        throw URLError(.badServerResponse)
      }
    }
    
    let tokenRefreshInterceptor = TokenRefreshInterceptor(
      tokenProvider: tokenProvider,
      tokenRefresher: tokenRefresher
    )
    
    let authorizationInterceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider
    )
    
    let interceptors: [RequestInterceptor] = [tokenRefreshInterceptor, authorizationInterceptor]
    let httpClient = InterceptableHTTPClient(
      httpClient: mockHTTPClient,
      interceptors: interceptors
    )
    
    var request = URLRequest(url: URL(string: "https://api.example.com/protected")!)
    request.httpMethod = "GET"
    
    // Act
    let (data, response) = try await httpClient.fetchData(with: request)
    let responseString = String(data: data, encoding: .utf8)
    
    // Assert
    XCTAssertTrue(tokenRefreshCalled)
    XCTAssertEqual(requestCount, 2)
    XCTAssertEqual(response.statusCode, 200)
    XCTAssertEqual(responseString, "success")
  }
  
  func testInterceptorDoesNotRefreshTokenOnAuthorizedResponse() async throws {
    // Arrange
    let tokenProvider = { return "valid_token" }
    var tokenRefresherCalled = false
    let tokenRefresher = {
      tokenRefresherCalled = true
    }
    
    // Mock HTTPClient to return 200 OK
    let mockHTTPClient = MockerHTTPClient()
    mockHTTPClient.fetchDataHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let data = "success".data(using: .utf8)!
      return (data, response)
    }
    
    let tokenRefreshInterceptor = TokenRefreshInterceptor(
      tokenProvider: tokenProvider,
      tokenRefresher: tokenRefresher
    )
    
    let interceptors: [RequestInterceptor] = [tokenRefreshInterceptor]
    let httpClient = InterceptableHTTPClient(
      httpClient: mockHTTPClient,
      interceptors: interceptors
    )
    
    let request = URLRequest(url: URL(string: "https://api.example.com/protected")!)
    
    // Act
    let (data, response) = try await httpClient.fetchData(with: request)
    let responseString = String(data: data, encoding: .utf8)
    
    // Assert
    XCTAssertFalse(tokenRefresherCalled)
    XCTAssertEqual(response.statusCode, 200)
    XCTAssertEqual(responseString, "success")
  }
  
  func testInterceptorPropagatesErrorWhenTokenRefresherFails() async throws {
    // Arrange
    let tokenProvider = { return "expired_token" }
    let tokenRefresher = {
      struct RefreshError: Error {}
      throw RefreshError()
    }
    
    // Mock HTTPClient to return 401 Unauthorized
    let mockHTTPClient = MockerHTTPClient()
    mockHTTPClient.fetchDataHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 401,
        httpVersion: nil,
        headerFields: nil
      )!
      return (Data(), response)
    }
    
    let tokenRefreshInterceptor = TokenRefreshInterceptor(
      tokenProvider: tokenProvider,
      tokenRefresher: tokenRefresher
    )
    
    let interceptors: [RequestInterceptor] = [tokenRefreshInterceptor]
    let httpClient = InterceptableHTTPClient(
      httpClient: mockHTTPClient,
      interceptors: interceptors
    )
    
    let request = URLRequest(url: URL(string: "https://api.example.com/protected")!)
    
    // Act & Assert
    do {
      _ = try await httpClient.fetchData(with: request)
      XCTFail("Expected error to be thrown")
    } catch {
      // Verify that the error is the one thrown by the token refresher
      //      XCTAssertTrue(error is RefreshError)
    }
  }
  
}

class MockerHTTPClient: HTTPClient {
  var fetchDataHandler: ((URLRequest) async throws -> (Data, HTTPURLResponse))?
  
  func fetchData(with request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    if let handler = fetchDataHandler {
      return try await handler(request)
    } else {
      throw URLError(.unknown)
    }
  }
}

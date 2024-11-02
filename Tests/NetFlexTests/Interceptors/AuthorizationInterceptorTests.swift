import XCTest
@testable import NetFlex

class AuthorizationInterceptorTests: XCTestCase {
  func testInterceptorAddsTokenToHeader() async throws {
    // Arrange
    let expectedToken = "test_token"
    let tokenProvider = { return expectedToken }
    let interceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider
    )
    
    var request = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    
    // Act
    request = try await interceptor.intercept(request: request)
    
    // Assert
    let authorizationHeader = request.value(forHTTPHeaderField: "Authorization")
    XCTAssertEqual(authorizationHeader, "Bearer \(expectedToken)")
  }
  
  func testInterceptorDoesNotModifyRequestWhenTokenIsNil() async throws {
    // Arrange
    let tokenProvider = { return nil as String? }
    let interceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider
    )
    
    let originalRequest = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    var request = originalRequest
    
    // Act
    request = try await interceptor.intercept(request: request)
    
    // Assert
    XCTAssertEqual(request, originalRequest)
  }
  
  func testInterceptorAddsTokenWithCustomHeaderAndFormat() async throws {
    // Arrange
    let expectedToken = "custom_token"
    let tokenProvider = { return expectedToken }
    let headerField = "X-API-Key"
    let tokenFormatter: (String) -> String = { "Token \($0)" }
    let interceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider,
      headerField: headerField,
      tokenFormatter: tokenFormatter
    )
    
    var request = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    
    // Act
    request = try await interceptor.intercept(request: request)
    
    // Assert
    let headerValue = request.value(forHTTPHeaderField: headerField)
    XCTAssertEqual(headerValue, "Token \(expectedToken)")
  }
  
  func testInterceptorAddsTokenToQueryParameters() async throws {
    // Arrange
    let expectedToken = "query_token"
    let tokenProvider = { return expectedToken }
    let interceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider,
      headerField: nil, // Do not add to headers
      addTokenToQuery: true,
      queryParameterName: "api_key"
    )
    
    var request = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    
    // Act
    request = try await interceptor.intercept(request: request)
    
    // Assert
    let urlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
    let queryItem = urlComponents?.queryItems?.first { $0.name == "api_key" }
    XCTAssertEqual(queryItem?.value, expectedToken)
  }
  
  func testInterceptorAddsTokenToRequestBody() async throws {
    // Arrange
    let expectedToken = "body_token"
    let tokenProvider = { return expectedToken }
    let interceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider,
      headerField: nil, // Do not add to headers
      addTokenToBody: true,
      bodyParameterName: "access_token"
    )
    
    var request = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    request.httpMethod = "POST"
    
    // Act
    request = try await interceptor.intercept(request: request)
    
    // Assert
    let bodyData = request.httpBody
    let bodyString = String(data: bodyData ?? Data(), encoding: .utf8)
    XCTAssertEqual(bodyString, "access_token=\(expectedToken)")
  }
  
  func testInterceptorPreservesExistingQueryParameters() async throws {
    // Arrange
    let expectedToken = "query_token"
    let tokenProvider = { return expectedToken }
    let interceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider,
      headerField: nil,
      addTokenToQuery: true,
      queryParameterName: "api_key"
    )
    
    var urlComponents = URLComponents(string: "https://api.example.com/resource")!
    urlComponents.queryItems = [URLQueryItem(name: "existing_param", value: "value")]
    var request = URLRequest(url: urlComponents.url!)
    
    // Act
    request = try await interceptor.intercept(request: request)
    
    // Assert
    let newUrlComponents = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)
    let queryItems = newUrlComponents?.queryItems
    XCTAssertEqual(queryItems?.count, 2)
    XCTAssertTrue(queryItems?.contains(URLQueryItem(name: "existing_param", value: "value")) ?? false)
    XCTAssertTrue(queryItems?.contains(URLQueryItem(name: "api_key", value: expectedToken)) ?? false)
  }
  
  func testInterceptorAppendsTokenToExistingBody() async throws {
    // Arrange
    let expectedToken = "body_token"
    let tokenProvider = { return expectedToken }
    let interceptor = AuthorizationInterceptor(
      tokenProvider: tokenProvider,
      headerField: nil,
      addTokenToBody: true,
      bodyParameterName: "access_token"
    )
    
    var request = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    request.httpMethod = "POST"
    let existingBody = "param1=value1"
    request.httpBody = existingBody.data(using: .utf8)
    
    // Act
    request = try await interceptor.intercept(request: request)
    
    // Assert
    let bodyData = request.httpBody
    let bodyString = String(data: bodyData ?? Data(), encoding: .utf8)
    let expectedBody = "\(existingBody)&access_token=\(expectedToken)"
    XCTAssertEqual(bodyString, expectedBody)
  }
}

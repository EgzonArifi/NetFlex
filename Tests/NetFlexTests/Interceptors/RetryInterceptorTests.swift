import XCTest
@testable import NetFlex

class RetryInterceptorTests: XCTestCase {
  func testRetryInterceptorRetriesOnTransientErrorAndSucceeds() async throws {
    // Arrange
    let maxRetryCount = 3
    let retryInterceptor = RetryInterceptor()
    
    var attemptCount = 0
    let mockHTTPClient = MockerHTTPClient()
    mockHTTPClient.fetchDataHandler = { request in
      attemptCount += 1
      if attemptCount < 3 {
        // Simulate 500 Internal Server Error
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 500,
          httpVersion: nil,
          headerFields: nil
        )!
        return (Data(), response)
      } else {
        // Simulate successful response
        let response = HTTPURLResponse(
          url: request.url!,
          statusCode: 200,
          httpVersion: nil,
          headerFields: nil
        )!
        let data = "success".data(using: .utf8)!
        return (data, response)
      }
    }
    
    let interceptors: [RequestInterceptor] = [retryInterceptor]
    let httpClient = InterceptableHTTPClient(
      httpClient: mockHTTPClient,
      interceptors: interceptors,
      maxRetryCount: maxRetryCount
    )
    
    let request = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    
    // Act
    let (data, response) = try await httpClient.fetchData(with: request)
    let responseString = String(data: data, encoding: .utf8)
    
    // Assert
    XCTAssertEqual(attemptCount, 3)
    XCTAssertEqual(response.statusCode, 200)
    XCTAssertEqual(responseString, "success")
  }
  
  func testRetryInterceptorStopsAfterMaxRetries() async throws {
    // Arrange
    let maxRetryCount = 2
    let retryInterceptor = RetryInterceptor()
    
    var attemptCount = 0
    let mockHTTPClient = MockerHTTPClient()
    mockHTTPClient.fetchDataHandler = { request in
      attemptCount += 1
      // Always return 500 Internal Server Error
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 500,
        httpVersion: nil,
        headerFields: nil
      )!
      return (Data(), response)
    }
    
    let interceptors: [RequestInterceptor] = [retryInterceptor]
    let httpClient = InterceptableHTTPClient(
      httpClient: mockHTTPClient,
      interceptors: interceptors,
      maxRetryCount: maxRetryCount
    )
    
    let request = URLRequest(url: URL(string: "https://api.example.com/resource")!)
    
    // Act & Assert
    do {
      _ = try await httpClient.fetchData(with: request)
      XCTFail("Expected error to be thrown")
    } catch {
      XCTAssertEqual(attemptCount, maxRetryCount + 1) // Initial attempt + retries
    }
  }
}

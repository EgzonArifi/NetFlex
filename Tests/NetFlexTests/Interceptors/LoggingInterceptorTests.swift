import XCTest
@testable import NetFlex

class LoggingInterceptorTests: XCTestCase {
  func testLoggingInterceptorOutputsLogs() async throws {
    // Arrange
    var capturedLogs = ""
    let loggingInterceptor = LoggingInterceptor { message in
      capturedLogs += message
    }
    let mockHTTPClient = MockerHTTPClient()
    mockHTTPClient.fetchDataHandler = { request in
      let response = HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
      )!
      let data = "response_data".data(using: .utf8)!
      return (data, response)
    }
    
    let interceptors: [RequestInterceptor] = [loggingInterceptor]
    let httpClient = InterceptableHTTPClient(
      httpClient: mockHTTPClient,
      interceptors: interceptors
    )
    
    let request = URLRequest(url: URL(string: "https://api.example.com/logging")!)
    
    // Act
    _ = try await httpClient.fetchData(with: request)
    
    // Assert
    XCTAssertTrue(capturedLogs.contains("➡️ Request:"))
    XCTAssertTrue(capturedLogs.contains("⬅️ Response:"))
  }
}

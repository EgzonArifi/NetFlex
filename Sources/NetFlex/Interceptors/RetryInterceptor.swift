import Foundation

public class RetryInterceptor: RequestInterceptor {
  public func intercept(request: URLRequest) async throws -> URLRequest {
    return request
  }
  
  public func intercept(response: HTTPURLResponse, data: Data, for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    if (500...599).contains(response.statusCode) {
      // Optionally, introduce delay
      try await Task.sleep(nanoseconds: UInt64(1.0 * Double(NSEC_PER_SEC))) // 1-second delay
      throw InterceptorError.retryRequired
    }
    return (data, response)
  }
}



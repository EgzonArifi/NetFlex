import Foundation

public class RetryInterceptor: RequestInterceptor {
  let statusCodesRange: ClosedRange<Int>
  
  public init(statusCodesRange: ClosedRange<Int> = 500...599) {
    self.statusCodesRange = statusCodesRange
  }
  
  public func intercept(request: URLRequest) async throws -> URLRequest {
    request
  }
  
  public func intercept(response: HTTPURLResponse, data: Data, for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    if statusCodesRange.contains(response.statusCode) {
      // Optionally, introduce delay
      try await Task.sleep(nanoseconds: UInt64(1.0 * Double(NSEC_PER_SEC)))
      // Throw the error with associated error information
      throw InterceptorError.retryRequired(error: InvalidHTTPResponseError(statusCode: response.statusCode, data: data))
    }
    return (data, response)
  }
}



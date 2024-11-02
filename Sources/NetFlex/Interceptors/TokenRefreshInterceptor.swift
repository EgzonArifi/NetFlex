import Foundation

public class TokenRefreshInterceptor: RequestInterceptor {
  private let tokenProvider: () -> String?
  private let tokenRefresher: () async throws -> Void
  private let headerField: String?
  private let tokenFormatter: (String) -> String
  private let statusCodesToRefresh: Set<Int>
  
  init(
    tokenProvider: @escaping () -> String?,
    tokenRefresher: @escaping () async throws -> Void,
    headerField: String? = "Authorization",
    tokenFormatter: @escaping (String) -> String = { "Bearer \($0)" },
    statusCodesToRefresh: Set<Int> = [401]
  ) {
    self.tokenProvider = tokenProvider
    self.tokenRefresher = tokenRefresher
    self.headerField = headerField
    self.tokenFormatter = tokenFormatter
    self.statusCodesToRefresh = statusCodesToRefresh
  }
  
  public func intercept(request: URLRequest) async throws -> URLRequest {
    var request = request
    if let token = tokenProvider(), let headerField = headerField {
      let formattedToken = tokenFormatter(token)
      request.setValue(formattedToken, forHTTPHeaderField: headerField)
    }
    return request
  }
  
  public func intercept(response: HTTPURLResponse, data: Data, for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    if statusCodesToRefresh.contains(response.statusCode) {
      // Refresh the token
      try await tokenRefresher()
      
      // Signal that the request should be retried
      throw InterceptorError.retryRequired
    }
    return (data, response)
  }
}


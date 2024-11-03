import Foundation

public class AuthorizationInterceptor: RequestInterceptor {
  private let tokenProvider: () -> String?
  private let headerField: String?
  private let tokenFormatter: (String) -> String
  private let addTokenToQuery: Bool
  private let addTokenToBody: Bool
  private let queryParameterName: String?
  private let bodyParameterName: String?
  private let bodyEncoding: String.Encoding
  
  init(
    tokenProvider: @escaping () -> String?,
    headerField: String? = "Authorization",
    tokenFormatter: @escaping (String) -> String = { "Bearer \($0)" },
    addTokenToQuery: Bool = false,
    queryParameterName: String? = nil,
    addTokenToBody: Bool = false,
    bodyParameterName: String? = nil,
    bodyEncoding: String.Encoding = .utf8
  ) {
    self.tokenProvider = tokenProvider
    self.headerField = headerField
    self.tokenFormatter = tokenFormatter
    self.addTokenToQuery = addTokenToQuery
    self.queryParameterName = queryParameterName
    self.addTokenToBody = addTokenToBody
    self.bodyParameterName = bodyParameterName
    self.bodyEncoding = bodyEncoding
  }
  
  public func intercept(request: URLRequest) async throws -> URLRequest {
    var request = request
    guard let token = tokenProvider() else {
      return request
    }
    
    // Add token to header if specified
    if let headerField = headerField {
      let formattedToken = tokenFormatter(token)
      request.setValue(formattedToken, forHTTPHeaderField: headerField)
    }
    
    // Add token to query parameters if specified
    if addTokenToQuery, let queryParameterName = queryParameterName, let url = request.url {
      var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
      var queryItems = components?.queryItems ?? []
      queryItems.append(URLQueryItem(name: queryParameterName, value: token))
      components?.queryItems = queryItems
      request.url = components?.url
    }
    
    // Add token to body if specified
    if addTokenToBody, let bodyParameterName = bodyParameterName {
      var bodyData = request.httpBody ?? Data()
      var bodyString = String(data: bodyData, encoding: bodyEncoding) ?? ""
      let tokenParameter = "\(bodyParameterName)=\(token)"
      if !bodyString.isEmpty {
        bodyString += "&" + tokenParameter
      } else {
        bodyString = tokenParameter
      }
      bodyData = bodyString.data(using: bodyEncoding) ?? Data()
      request.httpBody = bodyData
      // Set appropriate content type if not already set
      if request.value(forHTTPHeaderField: "Content-Type") == nil {
        request.setValue("application/x-www-form-urlencoded; charset=\(bodyEncoding)", forHTTPHeaderField: "Content-Type")
      }
    }
    
    return request
  }
  
  public func intercept(response: HTTPURLResponse, data: Data, for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    // No modification to the response
    (data, response)
  }
}

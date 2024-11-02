import Foundation

public class LoggingInterceptor: RequestInterceptor {
  private let logger: (String) -> Void
  
  init(logger: @escaping (String) -> Void = { print($0) }) {
    self.logger = logger
  }
  
  public func intercept(request: URLRequest) async throws -> URLRequest {
    var logMessage = "➡️ Request: \(request.httpMethod ?? "") \(request.url?.absoluteString ?? "")\n"
    if let headers = request.allHTTPHeaderFields {
      logMessage += "Headers: \(headers)\n"
    }
    if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
      logMessage += "Body: \(bodyString)\n"
    }
    logger(logMessage)
    return request
  }
  
  public func intercept(response: HTTPURLResponse, data: Data, for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    var logMessage = "⬅️ Response: \(response.statusCode) for \(request.url?.absoluteString ?? "")\n"
    if let responseString = String(data: data, encoding: .utf8) {
      logMessage += "Response Body: \(responseString)\n"
    }
    logger(logMessage)
    return (data, response)
  }
}

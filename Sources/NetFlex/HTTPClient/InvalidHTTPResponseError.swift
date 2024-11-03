import Foundation

public struct InvalidHTTPResponseError: LocalizedError {
  public let statusCode: Int
  public let data: Data?
  
  public var errorDescription: String? {
    "Invalid HTTP response with status code: \(statusCode)"
  }
  
  public init(statusCode: Int, data: Data?) {
    self.statusCode = statusCode
    self.data = data
  }
}

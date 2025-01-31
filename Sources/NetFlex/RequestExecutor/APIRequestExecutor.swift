import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public final class APIRequestExecutor {
  private let requestBuilder: URLRequestBuilder
  private let httpClient: HTTPClient
  private let jsonDecoder: JSONDecoding
  private let jsonEncoder: JSONEncoding
  private let validStatusCodes: Set<Int>
  private let errorHandler: APIErrorHandler?
  
  public init(
    requestBuilder: URLRequestBuilder,
    httpClient: HTTPClient = URLSessionHTTPClient(),
    jsonDecoder: JSONDecoding = JSONDecoder(),
    jsonEncoder: JSONEncoding = JSONEncoder(),
    validStatusCodes: Set<Int> = Set(200...299),
    errorHandler: APIErrorHandler? = nil
  ) {
    self.requestBuilder = requestBuilder
    self.httpClient = httpClient
    self.jsonDecoder = jsonDecoder
    self.jsonEncoder = jsonEncoder
    self.validStatusCodes = validStatusCodes
    self.errorHandler = errorHandler
  }
}

extension APIRequestExecutor: RequestExecutor {
  public func send<R: Request>(_ request: R) async throws -> R.Response {
    let urlRequest = try requestBuilder.build(from: request)
    return try await execute(with: urlRequest)
  }
  
  private func execute<T: Decodable>(with request: URLRequest) async throws -> T {
    do {
      let (data, httpResponse) = try await httpClient.fetchData(with: request)
      
      guard validStatusCodes.contains(httpResponse.statusCode) else {
        if let errorHandler = errorHandler {
          return try errorHandler.handleError(data: data, statusCode: httpResponse.statusCode)
        } else {
          throw InvalidHTTPResponseError(statusCode: httpResponse.statusCode, data: data)
        }
      }
      
      return try jsonDecoder.decode(T.self, from: data)
    } catch let error as InvalidHTTPResponseError {
      if let errorHandler = errorHandler, let data = error.data {
        return try errorHandler.handleError(data: data, statusCode: error.statusCode)
      } else {
        throw error
      }
    } catch {
      throw error
    }
  }
}

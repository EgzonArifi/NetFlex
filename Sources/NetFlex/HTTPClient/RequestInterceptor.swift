import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

protocol RequestInterceptor {
  func intercept(request: URLRequest) async throws -> URLRequest
  func intercept(response: HTTPURLResponse, data: Data, for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}

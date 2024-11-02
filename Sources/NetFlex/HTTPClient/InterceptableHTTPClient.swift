import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

class InterceptableHTTPClient: HTTPClient {
  private let httpClient: HTTPClient
  private let interceptors: [RequestInterceptor]
  private let maxRetryCount: Int
  
  init(httpClient: HTTPClient = URLSessionHTTPClient(), interceptors: [RequestInterceptor] = [], maxRetryCount: Int = 3) {
    self.httpClient = httpClient
    self.interceptors = interceptors
    self.maxRetryCount = maxRetryCount
  }
  
  func fetchData(with request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    var attempt = 0
    var lastError: Error?
    var request = request
    
    while true {
      do {
        attempt += 1
        // Apply request interceptors
        for interceptor in interceptors {
          request = try await interceptor.intercept(request: request)
        }
        
        // Perform the network request
        let (data, response) = try await httpClient.fetchData(with: request)
        
        var modifiedData = data
        var modifiedResponse = response
        
        // Apply response interceptors
        for interceptor in interceptors {
          (modifiedData, modifiedResponse) = try await interceptor.intercept(
            response: modifiedResponse,
            data: modifiedData,
            for: request
          )
        }
        
        // Success
        return (modifiedData, modifiedResponse)
        
      } catch InterceptorError.retryRequired {
        lastError = InterceptorError.retryRequired
        if attempt > maxRetryCount {
          break
        }
        continue
      } catch {
        throw error
      }
    }
    
    // Retries exhausted
    throw lastError ?? URLError(.cannotLoadFromNetwork)
  }
}

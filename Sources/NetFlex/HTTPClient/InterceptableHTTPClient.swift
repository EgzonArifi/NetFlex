import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

public class InterceptableHTTPClient: HTTPClient {
  private let httpClient: HTTPClient
  private let interceptors: [RequestInterceptor]
  private let maxRetryCount: Int
  
  public init(httpClient: HTTPClient = URLSessionHTTPClient(), interceptors: [RequestInterceptor] = [], maxRetryCount: Int = 3) {
    self.httpClient = httpClient
    self.interceptors = interceptors
    self.maxRetryCount = maxRetryCount
  }
  
  public  func fetchData(with request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    var attempt = 0
    var lastError: Error?
    
    retryLoop: while attempt <= maxRetryCount {
      var currentRequest = request
      attempt += 1
      
      do {
        // Apply request interceptors
        for interceptor in interceptors {
          currentRequest = try await interceptor.intercept(request: currentRequest)
        }
        
        // Perform the network request
        let (data, response) = try await httpClient.fetchData(with: currentRequest)
        
        var modifiedData = data
        var modifiedResponse = response
        
        // Apply response interceptors
        for interceptor in interceptors {
          do {
            (modifiedData, modifiedResponse) = try await interceptor.intercept(
              response: modifiedResponse,
              data: modifiedData,
              for: currentRequest
            )
          } catch InterceptorError.retryRequired(let error) {
            lastError = error
            if attempt > maxRetryCount {
              throw lastError!
            } else {
              continue retryLoop // Retry the request
            }
          }
        }
        
        // Success
        return (modifiedData, modifiedResponse)
        
      } catch InterceptorError.retryRequired(let error) {
        lastError = error
        if attempt > maxRetryCount {
          throw lastError!
        } else {
          continue retryLoop // Retry the request
        }
      } catch {
        // Non-retryable error
        throw error
      }
    }
    
    // Retries exhausted
    throw lastError ?? URLError(.cannotLoadFromNetwork)
  }
}

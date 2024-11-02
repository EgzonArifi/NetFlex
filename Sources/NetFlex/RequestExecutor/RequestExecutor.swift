import Foundation

public protocol RequestExecutor {
  func send<R: Request>(_ request: R) async throws -> R.Response
}

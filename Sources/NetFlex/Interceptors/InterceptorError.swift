import Foundation

enum InterceptorError: Error {
  case retryRequired(error: Error)
}

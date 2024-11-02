import Foundation
@testable import NetFlex

class FailingURLComponents: URLComponentsProvider {
  var queryItems: [URLQueryItem]?
  
  var url: URL? {
    return nil
  }
}

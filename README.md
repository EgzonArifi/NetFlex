<p align="center">
    <a href="Resources/Docs/README.md">
      <img src="Resources/Images/netflex.png" width="50%" alt="Lingua" />
    </a>
</p>
<p align="center">
    <a href="https://www.swift.org" alt="Swift">
        <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" />
    </a>
    <a href="./LICENSE" alt="License">
        <img src="https://img.shields.io/badge/Licence-MIT-green.svg" />
    </a>
    <a href="https://github.com/egzonarifi/netflex/actions/workflows/tests.yml" alt="Tests Status">
        <img src="https://github.com/egzonarifi/netflex/actions/workflows/tests.yml/badge.svg" />
    </a>
</p>

# NetFlex

A simple, scalable, and testable networking library for Swift.

## Features

- 🏗 **Modular Architecture**: Easily customize and extend the networking layer.
- 💪 **Type-Safe Requests**: Strong typing for API requests and responses.
- 📦 **Lightweight**: Built on top of URLSession for minimal overhead.
- 🚀 **Modern Concurrency**: Supports async/await in Swift.
- 🔄 **Interceptor Support**: Modify requests and responses globally.
- 🔐 **Automatic Token Refresh**: Built-in support for token refreshing.
- 📝 **Logging**: Customizable logging for debugging and monitoring.
- 🔄 **Retry Mechanism**: Implement retries with customizable policies.
- 🔧 **Unit Tested**: Comprehensive tests for reliability.

## Components

### HTTPClient

The `HTTPClient` protocol is responsible for making raw HTTP requests and returning the data and response. It abstracts the underlying URLSession and can be easily mocked for testing.

### URLSessionHTTPClient

`URLSessionHTTPClient` is a concrete implementation of `HTTPClient` that uses URLSession to make network requests. It can be configured with custom URLSession instances.

### RequestExecutor

`RequestExecutor` is a protocol for executing API requests and decoding responses into specified Swift model types.

### APIRequestExecutor

`APIRequestExecutor` is a concrete implementation of `RequestExecutor`. It uses the provided `HTTPClient` to fetch data and decodes it into the specified model types.

### Interceptors

Interceptors allow you to modify requests and responses globally. This is useful for adding headers, logging, error handling, token refreshing, and more.

- **RequestInterceptor**: A protocol for intercepting and modifying requests and responses.
- **AuthorizationInterceptor**: Adds authentication credentials to requests.
- **TokenRefreshInterceptor**: Handles automatic token refreshing upon receiving unauthorized responses.
- **LoggingInterceptor**: Provides customizable logging for requests and responses.
- **RetryInterceptor**: Implements retry logic for transient errors with customizable policies.

## Usage

This networking library provides a convenient way to make API requests using `APIRequestExecutor` and `RequestExecutor`. Below, you will find examples of how to use these components to create and send API requests.

### 1. Create a Request

First, define a custom request type that conforms to the `Request` protocol. Include all necessary information for the API endpoint, such as the HTTP method, path, query parameters, and request body.

```swift
struct GetUserByIdRequest: Request {
    typealias Response = User

    let id: String

    var method: HTTPMethod {
        .get
    }

    var path: String {
        "/users/\(id)"
    }
}
```

### 2. Initialize the APIRequestExecutor

#### Without Interceptors

```swift
let baseURL = URL(string: "https://api.example.com")!
let requestBuilder = DefaultURLRequestBuilder(baseURL: baseURL)
let httpClient = URLSessionHTTPClient()
let apiExecutor = APIRequestExecutor(
    requestBuilder: requestBuilder,
    httpClient: httpClient
)
```

#### With Interceptors

To utilize interceptors like authentication, logging, and retries:

```swift
// Token provider and refresher
let tokenProvider = { () -> String? in
    return TokenStorage.shared.accessToken
}

let tokenRefresher = {
    try await AuthService.refreshToken()
}

// Initialize interceptors
let authorizationInterceptor = AuthorizationInterceptor(
    tokenProvider: tokenProvider,
    headerField: "Authorization",
    tokenFormatter: { "Bearer \($0)" }
)

let tokenRefreshInterceptor = TokenRefreshInterceptor(
    tokenProvider: tokenProvider,
    tokenRefresher: tokenRefresher,
    headerField: "Authorization",
    tokenFormatter: { "Bearer \($0)" },
    statusCodesToRefresh: [401]
)

let loggingInterceptor = LoggingInterceptor()
let retryInterceptor = RetryInterceptor(maxRetryCount: 3)

let interceptors: [RequestInterceptor] = [
    tokenRefreshInterceptor,
    authorizationInterceptor,
    loggingInterceptor,
    retryInterceptor
]

// Create an InterceptableHTTPClient
let httpClient = InterceptableHTTPClient(
    httpClient: URLSessionHTTPClient(),
    interceptors: interceptors,
    maxRetryCount: 3
)

let apiExecutor = APIRequestExecutor(
    requestBuilder: requestBuilder,
    httpClient: httpClient
)
```

### 3. Send the Request

Use the `send(_:)` function to send your request.

```swift
let getUserRequest = GetUserByIdRequest(id: "123")

do {
    let user = try await apiExecutor.send(getUserRequest)
    print("User: \(user)")
} catch {
    print("Error: \(error)")
}
```

## Advanced Usage

### Customizing Authentication

If your API requires a different authentication scheme, customize the `AuthorizationInterceptor`.

#### Custom Header and Token Format

```swift
let authorizationInterceptor = AuthorizationInterceptor(
    tokenProvider: tokenProvider,
    headerField: "X-API-Key",
    tokenFormatter: { $0 } // Use the token as is
)
```

#### Adding Token to Query Parameters

```swift
let authorizationInterceptor = AuthorizationInterceptor(
    tokenProvider: tokenProvider,
    headerField: nil, // Do not add to headers
    addTokenToQuery: true,
    queryParameterName: "api_key"
)
```

### Token Refreshing

Handle automatic token refreshing with `TokenRefreshInterceptor`:

```swift
let tokenRefreshInterceptor = TokenRefreshInterceptor(
    tokenProvider: tokenProvider,
    tokenRefresher: tokenRefresher,
    headerField: "Authorization",
    tokenFormatter: { "Bearer \($0)" },
    statusCodesToRefresh: [401, 403]
)
```

### Logging

Use `LoggingInterceptor` to log requests and responses:

```swift
let loggingInterceptor = LoggingInterceptor()
```

### Retry Mechanism

Implement retries for transient errors:

```swift
let retryInterceptor = RetryInterceptor(maxRetryCount: 3, retryDelay: 1.0)
```

### Combining Interceptors

Combine multiple interceptors:

```swift
let interceptors: [RequestInterceptor] = [
    tokenRefreshInterceptor,
    authorizationInterceptor,
    loggingInterceptor,
    retryInterceptor
]

let httpClient = InterceptableHTTPClient(
    httpClient: URLSessionHTTPClient(),
    interceptors: interceptors,
    maxRetryCount: 3
)
```

## Customization

- **Interceptors**: Create custom interceptors by conforming to the `RequestInterceptor` protocol.
- **Error Handling**: Provide an `APIErrorHandler` to handle API-specific errors.
- **Custom HTTPClient**: Create a class conforming to `HTTPClient` for specific configurations.

## Testing

- **Unit Tests**: NetFlex includes comprehensive unit tests for all components.
- **Mocking**: Use `MockHTTPClient` and `MockURLProtocol` for testing.
- **Testing Interceptors**: Write unit tests for interceptors to verify their behavior.

## Installation

Add NetFlex to your project using Swift Package Manager:

```swift
dependencies: [
    .package(url: "https://github.com/egzonarifi/NetFlex.git", from: "1.0.1")
]
```

## License

NetFlex is released under the MIT license. See LICENSE for details.

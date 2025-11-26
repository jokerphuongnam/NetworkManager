import Foundation

public enum RetryResult: Sendable {
    /// Retry should be attempted immediately.
    case retry
    /// Retry should be attempted after the associated `TimeInterval`.
    case retryWithDelay(TimeInterval)
    /// Do not retry.
    case doNotRetry
    /// Do not retry due to the associated `Error`.
    case doNotRetryWithError(any Error)
}

public protocol RestAPIInterceptor: Sendable {
    func intercept(
        request: URLRequest,
        completion: @Sendable @escaping (Result<URLRequest, Error>) -> Void
    )
    
    func intercept(
        response result: Result<(Data, URLResponse), Error>,
        for request: URLRequest,
        completion: @Sendable @escaping (Result<(Data, URLResponse), Error>) -> Void
    )
    
    func retry(
        response result: Result<(Data, URLResponse), Error>,
        for request: URLRequest,
        completion: @Sendable @escaping (RetryResult) -> Void
    )
}

public extension RestAPIInterceptor {
    func intercept(
        response result: Result<(Data, URLResponse), Error>,
        for request: URLRequest,
        completion: @Sendable @escaping (Result<(Data, URLResponse), Error>) -> Void
    ) {
        completion(result)
    }
    
    func retry(
        response result: Result<(Data, URLResponse), Error>,
        for request: URLRequest,
        completion: @Sendable @escaping (RetryResult) -> Void
    ) {
        completion(.doNotRetry)
    }
}

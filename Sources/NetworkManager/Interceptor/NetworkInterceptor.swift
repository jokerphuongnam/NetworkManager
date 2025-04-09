import Foundation

public protocol NetworkInterceptor: Sendable {
    func intercept(request: URLRequest, completion: (Result<URLRequest, Error>) -> Void)
}

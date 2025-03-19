import Foundation

public protocol NMInterceptor: Sendable {
    func intercept(request: URLRequest, completion: (Result<URLRequest, Error>) -> Void)
}

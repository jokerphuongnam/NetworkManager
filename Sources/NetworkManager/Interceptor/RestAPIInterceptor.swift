import Foundation

public protocol RestAPIInterceptor: Sendable {
    func intercept(request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void)
    func intercept(response result: Result<(Data, URLResponse), Error>, for request: URLRequest, completion: @escaping (Result<(Data, URLResponse), Error>) -> Void)
}

public extension RestAPIInterceptor {
    func intercept(response result: Result<(Data, URLResponse), Error>, for request: URLRequest, completion: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        completion(result)
    }
}

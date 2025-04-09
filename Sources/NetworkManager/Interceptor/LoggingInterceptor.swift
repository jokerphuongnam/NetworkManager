import Foundation

public struct LoggingInterceptor: RestAPIInterceptor {
    public init() {}

    public func intercept(request: URLRequest, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        let method = request.httpMethod ?? "UNKNOWN"
        let urlString = request.url?.absoluteString ?? "nil"
        print("📤 [Request] \(method) \(urlString)")
        completion(.success(request))
    }

    public func intercept(response result: Result<(Data, URLResponse), Error>, for request: URLRequest, completion: @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        switch result {
        case .success((_, let response)):
            if let httpResponse = response as? HTTPURLResponse {
                print("📥 [Response] \(httpResponse.statusCode) from \(httpResponse.url?.absoluteString ?? "unknown URL")")
            } else {
                print("📥 [Response] Success but response is not HTTPURLResponse")
            }
        case .failure(let error):
            print("❌ [Error] \(error.localizedDescription) from \(request.url?.absoluteString ?? "unknown URL")")
        }
        completion(result)
    }
}

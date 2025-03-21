import Foundation

public struct URLSessionClient: Client {
    private let urlSession: URLSession
    public static let shared: Self = .init(urlSession: .shared)
    
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    public func sendRequest(url: URL, method: String, headers: [String: String], cookie: HTTPCookie?, interceptors: [NMInterceptor], body: Data?, completion: @Sendable @escaping (Result<Response<Data>, Error>) -> Void) -> Request {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.allHTTPHeaderFields = (urlSession.configuration.httpAdditionalHeaders as? [String: String] ?? [:]).merging(headers) { _, new in new }
        urlRequest.httpBody = body
        if let cookie {
            urlRequest.applyCookie(cookie)
        }
        return NMInterceptorChain(interceptors: interceptors).proceed(request: urlRequest) { result in
            switch result {
            case .success(let urlRequest):
                let task = urlSession.dataTask(
                    with: urlRequest
                ) { data, response, error in
                    if let error {
                        completion(.failure(error))
                        return
                    }
                    if let httpResponse = response as? HTTPURLResponse, let data {
                        let headers = httpResponse.allHeaderFields.compactMapValues { $0 as? String } as? [String: String] ?? [:]
                        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
                        completion(.success(Response(data: data, statusCode: httpResponse.statusCode, headers: headers, cookies: cookies)))
                    }
                }
                return URLSessionRequest(task: task)
            case .failure:
                return URLSessionRequest(task: nil)
            }
        }
    }
    
    func sendMultipartRequest(url: URL, method: String, headers: [String: String], body: Data?) {
        
    }
}

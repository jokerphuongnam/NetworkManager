import Foundation

public struct URLSessionClient: Client {
    private let urlSession: URLSession
    public static let shared: Self = .init(urlSession: .shared)
    
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    public func request(url: URL, method: String, headers: [String: String], cookie: HTTPCookie?, interceptors: [NMInterceptor], body: Data?, completion: @Sendable @escaping (Result<Response<Data>, Error>) -> Void) -> Request {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.allHTTPHeaderFields = (urlSession.configuration.httpAdditionalHeaders as? [String: String] ?? [:]).merging(headers) { _, new in new }
        if let cookie {
            urlRequest.applyCookie(cookie)
        }
        urlRequest.httpBody = body
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
    
    public func request(url: URL, method: String, headers: [String : String], cookie: HTTPCookie?, interceptors: [any NMInterceptor], body: Data?, parts: [MultiPartBody], completion: @Sendable @escaping (Result<Response<Data>, any Error>) -> Void) -> any Request {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.allHTTPHeaderFields = (urlSession.configuration.httpAdditionalHeaders as? [String: String] ?? [:]).merging(headers) { _, new in new }
        if let cookie {
            urlRequest.applyCookie(cookie)
        }
        urlRequest.httpBody = createMultipartData(body: body, parts: parts)
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
    
    private func createMultipartData(body: Data?, parts: [MultiPartBody]) -> Data? {
        guard !parts.isEmpty else {
            return body
        }
        
        var multipartData = Data()
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // Append JSON body if present
        if let body = body {
            multipartData.append("--\(boundary)\r\n".data(using: .utf8)!)
            multipartData.append("Content-Disposition: form-data; name=\"json\"\r\n".data(using: .utf8)!)
            multipartData.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            multipartData.append(body)
            multipartData.append("\r\n".data(using: .utf8)!)
        }
        
        // Append file parts
        for part in parts {
            multipartData.append("--\(boundary)\r\n".data(using: .utf8)!)
            multipartData.append("Content-Disposition: form-data; name=\"files\"; filename=\"\(part.name)\"\r\n".data(using: .utf8)!)
            multipartData.append("Content-Type: \(part.mineType)\r\n\r\n".data(using: .utf8)!)
            multipartData.append(part.content)
            multipartData.append("\r\n".data(using: .utf8)!)
        }
        
        // Close boundary
        multipartData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return multipartData
    }
}

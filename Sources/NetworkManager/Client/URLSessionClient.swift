import Foundation

public struct URLSessionClient: Client {
    private let urlSession: URLSession
    public static let shared: Self = .init(urlSession: .shared)
    
    public init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    public func request(url: URL, method: String, headers: [String: String], cookie: HTTPCookie?, interceptors: [RestAPIInterceptor], body: Data?, completion: @Sendable @escaping (Result<Response<Data>, Error>) -> Void) -> Request {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.allHTTPHeaderFields = (urlSession.configuration.httpAdditionalHeaders as? [String: String] ?? [:]).merging(headers) { _, new in new }
        if let cookie {
            urlRequest.applyCookie(cookie)
        }
        urlRequest.httpBody = body
        let interceptorsChain = RestAPIInterceptorChain(interceptors: interceptors)
        return interceptorsChain.proceed(request: urlRequest) { result in
            self.createRequest(for: url, interceptorsChain: interceptorsChain, result: result, completion: completion)
        }
    }
    
    public func request(url: URL, method: String, headers: [String : String], cookie: HTTPCookie?, interceptors: [any RestAPIInterceptor], body: Data?, parts: [String: MultiPartBody], completion: @Sendable @escaping (Result<Response<Data>, any Error>) -> Void) -> Request {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method
        urlRequest.allHTTPHeaderFields = (urlSession.configuration.httpAdditionalHeaders as? [String: String] ?? [:]).merging(headers) { _, new in new }
        if let cookie {
            urlRequest.applyCookie(cookie)
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = createMultipartData(boundary: boundary, body: body, parts: parts)
        let interceptorsChain = RestAPIInterceptorChain(interceptors: interceptors)
        return interceptorsChain.proceed(request: urlRequest) { result in
            self.createRequest(for: url, interceptorsChain: interceptorsChain, result: result, completion: completion)
        }
    }
    
    private func createRequest(for url: URL, interceptorsChain: RestAPIInterceptorChain, result: Result<URLRequest, Error>, completion: @Sendable @escaping (Result<Response<Data>, any Error>) -> Void) -> Request {
        switch result {
        case .success(let urlRequest):
            let task = urlSession.dataTask(
                with: urlRequest
            ) { data, response, error in
                let result: Result<(Data, URLResponse), Error>
                if let error {
                    result = .failure(error)
                } else if let data, let response {
                    result = .success((data, response))
                } else {
                    result = .failure(NSError(domain: "Unknown error", code: -1))
                }
                
                interceptorsChain.proceed(response: result, for: urlRequest) { result in
                    switch result {
                    case .success(let (data, response)):
                        if let httpResponse = response as? HTTPURLResponse {
                            let headers = httpResponse.allHeaderFields.compactMapValues { $0 as? String } as? [String: String] ?? [:]
                            let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
                            completion(.success(Response(data: data, statusCode: httpResponse.statusCode, headers: headers, cookies: cookies)))
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
            }
            return URLSessionRequest(task: task)
        case .failure(let error):
            DispatchQueue.global().async {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    completion(.failure(error))
                }
            }
            return URLSessionRequest(task: nil)
        }
    }
    private func createMultipartData(boundary: String, body: Data?, parts: [String: MultiPartBody]) -> Data? {
        guard !parts.isEmpty else {
            return body
        }
        
        var multipartData = Data()
        
        // Append JSON body if present
        if let body = body {
            multipartData.append("--\(boundary)\r\n".data(using: .utf8)!)
            multipartData.append("Content-Disposition: form-data; name=\"json\"\r\n".data(using: .utf8)!)
            multipartData.append("Content-Type: application/json\r\n\r\n".data(using: .utf8)!)
            multipartData.append(body)
            multipartData.append("\r\n".data(using: .utf8)!)
        }
        
        // Append file parts
        for (name, part) in parts {
            multipartData.append("--\(boundary)\r\n".data(using: .utf8)!)
            multipartData.append("Content-Disposition: form-data; name=\"\(name)\"; filename=\"\(part.name)\"\r\n".data(using: .utf8)!)
            multipartData.append("Content-Type: \(part.mimeType)\r\n\r\n".data(using: .utf8)!)
            multipartData.append(part.content)
            multipartData.append("\r\n".data(using: .utf8)!)
        }
        
        // Close boundary
        multipartData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        return multipartData
    }
}

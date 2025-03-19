//#if canImport(Alamofile)
import Alamofire
//#endif
import Foundation
import NetworkManager

public struct AlamofileClient: Client {
    private let session: Session
    public static let shared: AlamofileClient = .init(session: AF)
    
    init(session: Session) {
        self.session = session
    }
    
    public func sendRequest(url: URL, method: String, headers: [String: String], cookie: HTTPCookie?, interceptors: [NMInterceptor], body: Data?, completion: @Sendable @escaping (Result<Response<Data>, Error>) -> Void) -> NetworkManager.Request {
        let request = session.request(
            url,
            method: HTTPMethod(rawValue: method),
            parameters: nil,
            encoding: DataEncoding(data: body),
            interceptor: CookieInterceptorChain(
                interceptors: interceptors,
                cookie: cookie
            )
        )
        
        return AlamofireRequest(
            request: request.response { response in
                switch response.result {
                case .success(let data):
                    if let data,
                       let response = response.response {
                        let cookies = HTTPCookieStorage.shared.cookies(for: url) ?? []
                        completion(.success(Response(data: data, statusCode: response.statusCode, headers: headers, cookies: cookies)))
                    }
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        )
    }
}


struct DataEncoding: ParameterEncoding {
    let data: Data?
    
    func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data
        return request
    }
}

struct CookieInterceptorChain: RequestInterceptor {
    let interceptors: [NMInterceptor]
    let cookie: HTTPCookie?
    
    init(interceptors: [NMInterceptor], cookie: HTTPCookie?) {
        self.interceptors = interceptors
        self.cookie = cookie
    }
    
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, any Error>) -> Void) {
        var currentRequest = urlRequest
        if let cookie {
            currentRequest.applyCookie(cookie)
        }
        NMInterceptorChain(interceptors: interceptors)
            .proceed(request: urlRequest) { result in
                completion(result)
            }
    }
}

struct AlamofireRequest: NetworkManager.Request {
    private let request: DataRequest
    
    init(request: DataRequest) {
        self.request = request
    }
    
    func resume() {
        request.resume()
    }
    
    func cancel() {
        request.cancel()
    }
}

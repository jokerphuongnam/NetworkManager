import NetworkManager

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

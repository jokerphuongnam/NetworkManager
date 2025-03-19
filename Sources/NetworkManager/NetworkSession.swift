import Foundation

public struct NetworkSession: Sendable {
    private let baseUrl: URL
    private let client: Client
    public let converterFactory: ConverterFactory
    private let headers: [String: String]
    private let interceptors: [NMInterceptor]
    private let allowCookie: Bool
    
    public init(
        baseUrl: URL,
        client: Client,
        converterFactory: ConverterFactory,
        headers: [String: String],
        interceptors: [NMInterceptor],
        allowCookie: Bool = false
    ) {
        self.baseUrl = baseUrl
        self.client = client
        self.converterFactory = converterFactory
        self.headers = headers
        self.interceptors = interceptors
        self.allowCookie = allowCookie
    }
    
    public func request<RequestBody, ResponseBody>(url: String, method: String, headers: [String: String], isDefaultCookie: Bool?, cookie: HTTPCookie?, interceptors: [NMInterceptor], body: RequestBody) -> Call<Response<ResponseBody>> {
        let requestUrl = baseUrl.appendingPathComponent(url)
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        var call: Call<Response<ResponseBody>> = .init()
        
        
        do {
            call.request = client.sendRequest(
                url: requestUrl,
                method: method,
                headers: headers.merging(self.headers) { new, _ in new },
                cookie: requestCookie,
                interceptors: self.interceptors + interceptors,
                body: try converterFactory.requestBodyConverter(body: body)
            ) { result in
                switch result {
                case .success(let response):
                    do {
                        call.onResponse?(
                            try response.map { data in
                                try converterFactory.responseConverter(data: data)
                            }
                        )
                    } catch {
                        call.onFailure?(error)
                    }
                case .failure(let error):
                    call.onFailure?(error)
                }
            }
        } catch {
            call.onFailure?(error)
        }
        return call
    }
    
    public func request<ResponseBody>(url: String, method: String, headers: [String: String], isDefaultCookie: Bool?, cookie: HTTPCookie?, interceptors: [NMInterceptor]) -> Call<Response<ResponseBody>> {
        let requestUrl = URL(string: url, relativeTo: baseUrl)!
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        var call: Call<Response<ResponseBody>> = .init()
        
        call.request = client.sendRequest(
            url: requestUrl,
            method: method,
            headers: headers.merging(self.headers) { new, _ in new },
            cookie: requestCookie,
            interceptors: self.interceptors + interceptors,
            body: nil
        ) { result in
            switch result {
            case .success(let response):
                do {
                    call.onResponse?(
                        try response.map { data in
                            try converterFactory.responseConverter(data: data)
                        }
                    )
                } catch {
                    call.onFailure?(error)
                }
            case .failure(let error):
                call.onFailure?(error)
            }
        }
        return call
    }
    
    private func isResponse(_ typeString: String) -> Bool {
        let pattern = #"^Response<[^,<>]+>$"#
        return typeString.range(of: pattern, options: .regularExpression) != nil
    }
}

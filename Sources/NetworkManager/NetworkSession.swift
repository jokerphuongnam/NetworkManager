import Foundation

public struct NetworkSession: Sendable {
    private let baseUrl: URL
    private let client: Client
    public let converterFactory: ConverterFactory
    private let headers: [String: String]
    private let interceptors: [RestAPIInterceptor]
    private let allowCookie: Bool
    
    public init(
        baseUrl: URL,
        client: Client,
        converterFactory: ConverterFactory,
        headers: [String: String] = [:],
        interceptors: [RestAPIInterceptor] = [],
        allowCookie: Bool = false
    ) {
        self.baseUrl = baseUrl
        self.client = client
        self.converterFactory = converterFactory
        self.headers = headers
        self.interceptors = interceptors
        self.allowCookie = allowCookie
    }
    
    public func request<RequestBody, ResponseBody>(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil,
        body: RequestBody
    ) -> Call<Response<ResponseBody>> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<Response<ResponseBody>> = .init()
        
        do {
            if let parts {
                call.request = client.request(
                    url: requestUrl,
                    method: method,
                    headers: headers.merging(self.headers) { new, _ in new },
                    cookie: requestCookie,
                    interceptors: self.interceptors + interceptors,
                    body: try converterFactory.requestBodyConverter(body: body),
                    parts: parts
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
            } else {
                call.request = client.request(
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
            }
        } catch {
            Task { [weak call] in
                guard let call else { return }
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                call.onFailure?(error)
            }
        }
        return call
    }
    
    public func request<ResponseBody>(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil
    ) -> Call<Response<ResponseBody>> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<Response<ResponseBody>> = .init()
        
        if let parts {
            call.request = client.request(
                url: requestUrl,
                method: method,
                headers: headers.merging(self.headers) { new, _ in new },
                cookie: requestCookie,
                interceptors: self.interceptors + interceptors,
                body: nil,
                parts: parts
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
        } else {
            call.request = client.request(
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
        }
        return call
    }
    
    public func request<RequestBody, ResponseBody>(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil,
        body: RequestBody
    ) -> Call<ResponseBody> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<ResponseBody> = .init()
        
        do {
            if let parts {
                call.request = client.request(
                    url: requestUrl,
                    method: method,
                    headers: headers.merging(self.headers) { new, _ in new },
                    cookie: requestCookie,
                    interceptors: self.interceptors + interceptors,
                    body: try converterFactory.requestBodyConverter(body: body),
                    parts: parts
                ) { result in
                    switch result {
                    case .success(let response):
                        do {
                            call.onResponse?(
                                try converterFactory.responseConverter(data: response.data)
                            )
                        } catch {
                            call.onFailure?(error)
                        }
                    case .failure(let error):
                        call.onFailure?(error)
                    }
                }
            } else {
                call.request = client.request(
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
                                try converterFactory.responseConverter(data: response.data)
                            )
                        } catch {
                            call.onFailure?(error)
                        }
                    case .failure(let error):
                        call.onFailure?(error)
                    }
                }
            }
        } catch {
            Task { [weak call] in
                guard let call else { return }
                try? await Task.sleep(nanoseconds: 300_000_000)
                
                call.onFailure?(error)
            }
        }
        return call
    }
    
    public func request<ResponseBody>(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil
    ) -> Call<ResponseBody> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<ResponseBody> = .init()
        
        if let parts {
            call.request = client.request(
                url: requestUrl,
                method: method,
                headers: headers.merging(self.headers) { new, _ in new },
                cookie: requestCookie,
                interceptors: self.interceptors + interceptors,
                body: nil,
                parts: parts
            ) { result in
                switch result {
                case .success(let response):
                    do {
                        call.onResponse?(
                            try converterFactory.responseConverter(data: response.data)
                        )
                    } catch {
                        call.onFailure?(error)
                    }
                case .failure(let error):
                    call.onFailure?(error)
                }
            }
        } else {
            call.request = client.request(
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
                            try converterFactory.responseConverter(data: response.data)
                        )
                    } catch {
                        call.onFailure?(error)
                    }
                case .failure(let error):
                    call.onFailure?(error)
                }
            }
        }
        return call
    }
    
    public func request<RequestBody>(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil,
        body: RequestBody
    ) -> Call<Response<Void>> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<Response<Void>> = .init()
        
        do {
            if let parts {
                call.request = client.request(
                    url: requestUrl,
                    method: method,
                    headers: headers.merging(self.headers) { new, _ in new },
                    cookie: requestCookie,
                    interceptors: self.interceptors + interceptors,
                    body: try converterFactory.requestBodyConverter(body: body),
                    parts: parts
                ) { result in
                    switch result {
                    case .success(let response):
                        call.onResponse?(
                            response.map { data in
                                ()
                            }
                        )
                    case .failure(let error):
                        call.onFailure?(error)
                    }
                }
            } else {
                call.request = client.request(
                    url: requestUrl,
                    method: method,
                    headers: headers.merging(self.headers) { new, _ in new },
                    cookie: requestCookie,
                    interceptors: self.interceptors + interceptors,
                    body: try converterFactory.requestBodyConverter(body: body)
                ) { result in
                    switch result {
                    case .success(let response):
                        call.onResponse?(
                            response.map { data in
                                ()
                            }
                        )
                    case .failure(let error):
                        call.onFailure?(error)
                    }
                }
            }
        } catch {
            call.onFailure?(error)
        }
        return call
    }
    
    public func request(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil
    ) -> Call<Response<Void>> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<Response<Void>> = .init()
        
        if let parts {
            call.request = client.request(
                url: requestUrl,
                method: method,
                headers: headers.merging(self.headers) { new, _ in new },
                cookie: requestCookie,
                interceptors: self.interceptors + interceptors,
                body: nil,
                parts: parts
            ) { result in
                switch result {
                case .success(let response):
                    call.onResponse?(
                        response.map { data in
                            ()
                        }
                    )
                case .failure(let error):
                    call.onFailure?(error)
                }
            }
        } else {
            call.request = client.request(
                url: requestUrl,
                method: method,
                headers: headers.merging(self.headers) { new, _ in new },
                cookie: requestCookie,
                interceptors: self.interceptors + interceptors,
                body: nil
            ) { result in
                switch result {
                case .success(let response):
                    call.onResponse?(
                        response.map { data in
                            ()
                        }
                    )
                case .failure(let error):
                    call.onFailure?(error)
                }
            }
        }
        return call
    }
    
    public func request<RequestBody>(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil,
        body: RequestBody
    ) -> Call<Void> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<Void> = .init()
        
        do {
            if let parts {
                call.request = client.request(
                    url: requestUrl,
                    method: method,
                    headers: headers.merging(self.headers) { new, _ in new },
                    cookie: requestCookie,
                    interceptors: self.interceptors + interceptors,
                    body: try converterFactory.requestBodyConverter(body: body),
                    parts: parts
                ) { result in
                    switch result {
                    case .success:
                        call.onResponse?(())
                    case .failure(let error):
                        call.onFailure?(error)
                    }
                }
            } else {
                call.request = client.request(
                    url: requestUrl,
                    method: method,
                    headers: headers.merging(self.headers) { new, _ in new },
                    cookie: requestCookie,
                    interceptors: self.interceptors + interceptors,
                    body: try converterFactory.requestBodyConverter(body: body)
                ) { result in
                    switch result {
                    case .success:
                        call.onResponse?(())
                    case .failure(let error):
                        call.onFailure?(error)
                    }
                }
            }
        } catch {
            call.onFailure?(error)
        }
        return call
    }
    
    public func request(
        url: String,
        method: String,
        headers: [String: String],
        isDefaultCookie: Bool?,
        cookie: HTTPCookie?,
        interceptors: [RestAPIInterceptor],
        parts: [String: MultiPartBody]? = nil
    ) -> Call<Void> {
        let requestUrl = if url.isEmpty { baseUrl } else { URL(string: url, relativeTo: baseUrl)! }
        let requestCookie: HTTPCookie?
        if let cookie {
            requestCookie = cookie
        } else if allowCookie && isDefaultCookie == nil || isDefaultCookie == true {
            requestCookie = HTTPCookieStorage.shared.cookies(for: requestUrl)?.first
        } else {
            requestCookie = nil
        }
        
        let call: Call<Void> = .init()
        
        if let parts {
            call.request = client.request(
                url: requestUrl,
                method: method,
                headers: headers.merging(self.headers) { new, _ in new },
                cookie: requestCookie,
                interceptors: self.interceptors + interceptors,
                body: nil,
                parts: parts
            ) { result in
                switch result {
                case .success:
                    call.onResponse?(())
                case .failure(let error):
                    call.onFailure?(error)
                }
            }
        } else {
            call.request = client.request(
                url: requestUrl,
                method: method,
                headers: headers.merging(self.headers) { new, _ in new },
                cookie: requestCookie,
                interceptors: self.interceptors + interceptors,
                body: nil
            ) { result in
                switch result {
                case .success:
                    call.onResponse?(())
                case .failure(let error):
                    call.onFailure?(error)
                }
            }
        }
        return call
    }
    
    private func isResponse(_ typeString: String) -> Bool {
        let pattern = #"^Response<[^,<>]+>$"#
        return typeString.range(of: pattern, options: .regularExpression) != nil
    }
}

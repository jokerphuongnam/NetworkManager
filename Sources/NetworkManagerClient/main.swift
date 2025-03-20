import NetworkManager
import Foundation
@preconcurrency import Combine

struct RequestBodyDemo {
    let id: Int
    let name: String
}

struct TestInterceptor: NMInterceptor {
    func intercept(request: URLRequest, completion: (Result<URLRequest, any Error>) -> Void) {
        completion(.success(request))
    }
}
struct AuthInterceptor: NMInterceptor {
    func intercept(request: URLRequest, completion: (Result<URLRequest, any Error>) -> Void) {
        completion(.success(request))
    }
}

struct GithubUsersResponse: Decodable {
    public let login: String
    public let avatarURL: String
    public let htmlURL: String
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

@NetworkGenerateProtocol(.struct, path: "test/", callAdapter: .combine)
protocol ProtocolDemo: Sendable {
    @GET("users")
    func users(
        perPage per_page: Query<Int>,
        since: Query<Int>
    ) -> Future<GithubUsersResponse, Error>
}

func getProtocolDemo() -> ProtocolDemo {
    ProtocolDemoImpl(
        session: NetworkSession(
            baseUrl: URL(string: "https://api.github.com")!,
            client: URLSessionClient.shared,
            converterFactory: JSONDecodableConverterFactory(),
            headers: ["Content-Type": "application/json; charset=utf-8"],
            interceptors: []
        )
    )
}

let demo = getProtocolDemo()

//Task.detached(priority: .background) {
//    var call = demo.users(
//        perPage: 5,
//        since: 4
//    )
//    
//    call.enqueue { response in
//        print(response)
//    } onFailure: { error in
//        print(error)
//    }
//}

Task {
    let response = try await demo.users(
        perPage: 5,
        since: 4
    )
    print(response)
}

//
//NetworkSession(
//    baseUrl: URL(string: "https://www.google.com")!,
//    client: URLSessionClient.shared,
//    converterFactory: JSONDecodableConverterFactory(),
//    headers: ["TestSingle-1": "RootValue","Service-Key": "test", "Service-key2": "test2"],
//    interceptors: []
//).request(
//    url: <#T##String#>,
//    method: <#T##String#>,
//    headers: <#T##[String : String]#>,
//    isDefaultCookie: <#T##Bool#>,
//    cookie: <#T##HTTPCookie?#>,
//    interceptors: <#T##[any NMInterceptorProtocol]#>,
//    body: <#T##Data#>
//)

struct ProtocolDemoImplAsync {
    private let session: NetworkSession
    private let headers: [String: String]
    private let interceptors: [NMInterceptor]

    init(
        session: NetworkSession,
        headers: [String: String] = [:],
        interceptors: [NMInterceptor] = []
    ) {
        self.session = session
        self.headers = headers
        self.interceptors = interceptors
    }
    
    func users(perPage per_page: Query<Int>, since: Query<Int>) async throws -> GithubUsersResponse {
        let headers = [:].merging(self.headers) { new, _ in
            new
        }
        
        let requestInterceptor = self.interceptors
        
        let call: Call<GithubUsersResponse> = session.request(
            url: "users?per_page=\(per_page.value)&since=\(since.value)",
            method: "GET",
            headers: headers,
            isDefaultCookie: nil,
            cookie: nil,
            interceptors: requestInterceptor
        )
        
        return try await withTaskCancellationHandler {
            return try await withCheckedThrowingContinuation { continuation in
                call.enqueue { response in
                    continuation.resume(returning: response)
                } onFailure: { error in
                    continuation.resume(throwing: error)
                }
                
            }
        } onCancel: {
            call.cancel()
        }
    }
}

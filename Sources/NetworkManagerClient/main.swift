import NetworkManager
import AlamofileClient
import Foundation

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

@NetworkGenerateProtocol
protocol ProtocolDemo: Sendable {
    @GET("users")
    func users(
        perPage per_page: Query<Int>,
        since: Query<Int>
    ) -> Call<Response<GithubUsersResponse>>
}

func getProtocolDemo() -> ProtocolDemo {
    ProtocolDemoImpl(
        session: NetworkSession(
            baseUrl: URL(string: "https://api.github.com")!,
            client: AlamofileClient.shared,
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

var call = demo.users(
    perPage: 5,
    since: 4
)

call.enqueue { response in
    print(response)
} onFailure: { error in
    print(error)
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

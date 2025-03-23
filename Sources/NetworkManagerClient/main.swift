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

struct GithubUsersResponse: Decodable, Sendable {
    public let login: String
    public let avatarURL: String
    public let htmlURL: String
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarURL = "avatar_url"
        case htmlURL = "html_url"
    }
}

public struct FetchGithubUserDetailsResponse: Decodable, Sendable {
    public let login: String
    public let avatarUrl: String
    public let htmlUrl: String
    public let location: String?
    public let followers: Int?
    public let following: Int?
    
    init(login: String, avatarUrl: String, htmlUrl: String, location: String?, followers: Int?, following: Int?) {
        self.login = login
        self.avatarUrl = avatarUrl
        self.htmlUrl = htmlUrl
        self.location = location
        self.followers = followers
        self.following = following
    }
    
    enum CodingKeys: String, CodingKey {
        case login
        case avatarUrl = "avatar_url"
        case htmlUrl = "html_url"
        case location
        case followers
        case following
    }
}

struct TestRequest {
    
}

struct Paging<T>: Sendable {}

@RestAPIService(.actor, path: "users", callAdapter: .combine)
protocol ProtocolDemo {
    @GET
    var users: Future<Paging<GithubUsersResponse>, Error> { get }
    
    @GET("{login_user}")
    func userDetail(
        loginUser login_user: Path<String>,
        body: TestRequest,
        firstFile: MultiPartBody,
        secondFile: MultiPartBody
    ) -> Future<Paging<GithubUsersResponse>, Error>
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

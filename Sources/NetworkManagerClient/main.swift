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

struct Paging<T>: Sendable {}

@NetworkGenerateProtocol(.actor, path: "users", callAdapter: .combine)
@preconcurrency protocol ProtocolDemo {
    @GET
    var users: Future<Paging<GithubUsersResponse>, Error> { get }
    
    @GET("{login_user}")
    func userDetail(
        loginUser login_user: Path<String>
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

//Task {
//    let response = try await demo.users
//    print(response)
//}

//var cancellables = Set<Cancellable>()
//
//demo.users.sink { print($0) }.store(in: &cancellables)

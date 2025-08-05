import NetworkManager
import Foundation
@preconcurrency import Combine

struct RequestBodyDemo {
    let id: Int
    let name: String
}

struct TestInterceptor: RestAPIInterceptor {
    func intercept(request: URLRequest, completion: (Result<URLRequest, any Error>) -> Void) {
        completion(.success(request))
    }
}
struct AuthInterceptor: RestAPIInterceptor {
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

struct TestRequest: Codable {
    let a: String
}

struct Paging<T>: Sendable {}

@RestAPIService(.actor, path: "users", callAdapter: .combine)
protocol ProtocolDemo: Sendable {
    @GET
    var users: Future<Paging<GithubUsersResponse>, Error> { get }
    
    @GET
    func testQueries(
        query: Query<Int8>,
        b: Query<Float64>?,
        interceptor: RestAPIInterceptor
    ) -> Future<GithubUsersResponse, Error>
    
    @GET
    func userDetail(
        //        loginUser login_user: Path<String>,
        body: TestRequest,
        firstFile: MultiPartBody,
        secondFile: MultiPartBody
    ) -> Future<GithubUsersResponse, Error>
    
    @GET
    func userDetails(
        loginUser login_user: Path<String>,
        body: TestRequest,
        firstFile: MultiPartBody,
        secondFile: MultiPartBody
    ) -> Future<Paging<GithubUsersResponse>, Error>
    
    @GET
    func userDetails(
        loginUser login_user: Path<String>,
        body: TestRequest
    ) -> Future<Paging<GithubUsersResponse>, Error>
}

@RestAPIService()
protocol HttpBin {
    @GET("cookies/set")
    func setCookie(cookie: HTTPCookie, sessionId: Query<String>) async throws -> Response<Void>
}

@available(iOS 14.0, *)
func getProtocolDemo() -> ProtocolDemo {
    ProtocolDemoImpl(
        session: NetworkSession(
            baseUrl: URL(string: "https://api.github.com")!,
            client: URLSessionClient.shared,
            converterFactory: JSONDecodableConverterFactory(),
            headers: ["Content-Type": "application/json; charset=utf-8"],
            interceptors: [LoggingInterceptor()]
        )
    )
}

@available(iOS 14.0, *)
func getHttpBin() -> HttpBin {
    HttpBinImpl(
        session: NetworkSession(
            baseUrl: URL(string: "https://httpbin.org")!,
            client: URLSessionClient.shared,
            converterFactory: JSONDecodableConverterFactory(),
            headers: ["Content-Type": "application/json; charset=utf-8"],
            interceptors: [LoggingInterceptor(level: .basic)]
        )
    )
}

//let demo = getProtocolDemo()
//demo.testQueries(query: 4, b: 2.0, interceptor: TestInterceptor()).sink { result in
//    switch result {
//        case .failure(let error):
//            print("Error occurred: \(error)")
//        case .finished:
//            print("Response")
//        }
//} receiveValue: { res in
//
//}
if #available(iOS 14.0, *) {
    let semaphore = DispatchSemaphore(value: 0)
    
    // MARK: - Post
    struct Post: Codable {
        let userID, id: Int
        let title, body: String
        
        enum CodingKeys: String, CodingKey {
            case userID = "userId"
            case id, title, body
        }
    }
    
    typealias Posts = [Post]
    
//    var cancellables = Set<AnyCancellable>()
    
//    let demo = getProtocolDemo()
//    demo.users
//        .subscribe(on: DispatchQueue.global(qos: .background))
//        .receive(on: RunLoop.main, options: nil)
//        .sink { _ in
//            semaphore.signal()
//        } receiveValue: { _ in
//
//        }
//        .store(in: &cancellables)
    Task.detached(priority: .background) {
        let httpBin: HttpBin = getHttpBin()
        
        let cookieProperties: [HTTPCookiePropertyKey: Any] = [
            .domain: "httpbin.org",
            .path: "/",
            .name: "sessionId",
            .value: "123456",
            .secure: true,
            .expires: Date().addingTimeInterval(600),
            .version: 5
        ]

        guard let cookie = HTTPCookie(properties: cookieProperties) else {
            print("❌ Failed to create cookie")
            semaphore.signal()
            return
        }
        
        let response = try await httpBin.setCookie(cookie: cookie, sessionId: "123456")
        print("====== ", response)
        if let cookies = HTTPCookieStorage.shared.cookies(for: URL(string: "https://httpbin.org")!) {
            for cookie in cookies {
                print("📦 Stored cookie: \(cookie.name)=\(cookie.value)")
            }
        }
    }
    semaphore.wait()
} else {
    // Fallback on earlier versions
}

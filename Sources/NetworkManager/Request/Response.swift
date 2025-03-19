import Foundation

public struct Response<T> {
    public let data: T
    public let statusCode: Int
    public let headers: [String: String]
    public let cookies: [HTTPCookie]
    
    public init(data: T, statusCode: Int, headers: [String : String], cookies: [HTTPCookie]) {
        self.data = data
        self.statusCode = statusCode
        self.headers = headers
        self.cookies = cookies
    }
    
    func map<R>(handler: (T) throws -> R) rethrows -> Response<R> {
        return Response<R>(
            data: try handler(
                data
            ),
            statusCode: statusCode,
            headers: headers,
            cookies: cookies
        )
    }
}

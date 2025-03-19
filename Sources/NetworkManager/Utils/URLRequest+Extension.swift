import Foundation

public extension URLRequest {
    mutating func applyCookie(_ cookie: HTTPCookie) {
        HTTPCookieStorage.shared.setCookie(cookie)
        if let cookieHeader = HTTPCookie.requestHeaderFields(with: [cookie])["Cookie"] {
            addValue(cookieHeader, forHTTPHeaderField: "Cookie")
        }
    }
}

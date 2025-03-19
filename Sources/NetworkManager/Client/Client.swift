import Foundation

public protocol Client: Sendable {
    func sendRequest(
        url: URL,
        method: String,
        headers: [String: String],
        cookie: HTTPCookie?,
        interceptors: [NMInterceptor],
        body: Data?,
        completion: @Sendable @escaping (Result<Response<Data>, Error>) -> Void
    ) -> Request
}


public func mimeType(for url: URL) -> String {
    switch url.pathExtension.lowercased() {
    case "jpg", "jpeg": return "image/jpeg"
    case "png": return "image/png"
    case "gif": return "image/gif"
    case "pdf": return "application/pdf"
    default: return "application/octet-stream"
    }
}

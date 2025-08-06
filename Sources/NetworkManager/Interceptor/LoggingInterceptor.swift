import Foundation
import SwiftUICore
import os
import UIKit

@available(iOS 14.0, *)
public final class LoggingInterceptor: RestAPIInterceptor, Sendable {
    public enum Level : Sendable {
        case headers
        case cookies
        case body
        case all
        case basic
    }
    
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "LoggingInterceptor", category: "Networking")
    private let startTime = SafeBox<Date?>(nil)
    private let level: Level?
    
    public init(level: Level? = nil) {
        self.level = level
    }
    
    public func intercept(request: URLRequest, completion: @Sendable @escaping (Result<URLRequest, Error>) -> Void) {
        if level == nil {
            completion(.success(request))
            return
        }
        
        startTime.value = Date()
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "nil"
        
        var log = "📤\n---> \(method) \(url)\n"
        
        if (level == .headers || level == .all), let headers = request.allHTTPHeaderFields, !headers.isEmpty {
            log += "Headers:\n"
            headers.forEach { log += "- \($0): \($1)\n" }
        }
        
        if (level == .cookies || level == .all), let cookies = HTTPCookieStorage.shared.cookies(for: request.url!), !cookies.isEmpty {
            log += "Cookies:\n"
            cookies.forEach { log += "- \($0.name)=\($0.value)\n" }
        }
        
        if (level == .body || level == .all), let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
            log += "Body:\n\(bodyString)\n"
        }
        
        log += "---> END \(method)"
        LoggingInterceptor.logger.debug("\(log, privacy: .public)")
        completion(.success(request))
    }
    
    public func intercept(response result: Result<(Data, URLResponse), Error>, for request: URLRequest, completion: @Sendable @escaping (Result<(Data, URLResponse), Error>) -> Void) {
        if level == nil {
            completion(result)
            return
        }
        let method = request.httpMethod ?? "UNKNOWN"
        let url = request.url?.absoluteString ?? "nil"
        
        switch result {
        case .success((let data, let response)):
            let elapsed = String(format: "%.2fms", Date().timeIntervalSince(startTime.value!) * 1000)
            var log = "📤\n<--- \(method) \(url) (\(elapsed))\n"

            if let httpResponse = response as? HTTPURLResponse {
                if let server = httpResponse.allHeaderFields["Server"] as? String {
                    log += "server: \(server)\n"
                }

                if let date = httpResponse.allHeaderFields["Date"] as? String {
                    log += "date: \(date)\n"
                }

                if (level == .headers || level == .all) {
                    let headers = httpResponse.allHeaderFields
                    if !headers.isEmpty {
                        log += "Headers:\n"
                        headers.forEach {
                            log += "- \($0): \($1)\n"
                        }
                    }
                    
                    if (level == .cookies || level == .all), let cookies = HTTPCookieStorage.shared.cookies(for: request.url!), !cookies.isEmpty {
                        log += "Cookies:\n"
                        cookies.forEach { log += "- \($0.name)=\($0.value)\n" }
                    }
                    
                    if (level == .body || level == .all), let bodyString = String(data: data, encoding: .utf8), !bodyString.isEmpty {
                        log += "Body:\n\(bodyString)\n"
                    }
                } else {
                    log += "Response not HTTPURLResponse\n"
                }
                
                log += "<--- END HTTP"
                LoggingInterceptor.logger.debug("\(log, privacy: .public)")
            }
        case .failure(let error):
            LoggingInterceptor.logger.error("❌ [Error] \(error.localizedDescription, privacy: .public) from \(url, privacy: .public)")
        }
        
        completion(result)
    }
}

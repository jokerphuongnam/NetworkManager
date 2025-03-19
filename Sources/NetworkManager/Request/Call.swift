import Foundation

public final class Call<Response>: @unchecked Sendable {
    var request: Request? = nil
    private(set) var onResponse: (@Sendable (Response) -> Void)? = nil
    private(set) var onFailure: (@Sendable (Error) -> Void)? = nil
    
    public init() {
        
    }
    
    public func cancel() {
        self.request?.cancel()
    }
    
    public func enqueue(onResponse: @Sendable @escaping (Response) -> Void, onFailure: @Sendable @escaping (Error) -> Void) {
        self.onResponse = onResponse
        self.onFailure = onFailure
        self.request?.resume()
    }
}

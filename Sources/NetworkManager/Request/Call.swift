import Foundation

public final class Call<Response>: @unchecked Sendable {
    var request: Request? = nil
    private(set) var onResponse: ((Response) -> Void)? = nil
    private(set) var onFailure: ((Error) -> Void)? = nil
    
    public init() {
        
    }
    
    public func cancel() {
        self.request?.cancel()
    }
    
    public func enqueue(onResponse: @escaping (Response) -> Void, onFailure: @escaping (Error) -> Void) {
        self.onResponse = onResponse
        self.onFailure = onFailure
        self.request?.resume()
    }
}

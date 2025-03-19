public struct Call<Response>: Sendable {
    var request: Request? = nil
    private(set) var onResponse: (@Sendable (Response) -> Void)? = nil
    private(set) var onFailure: (@Sendable (Error) -> Void)? = nil
    
    public init() {
        
    }
    
    public func cancel() {
        request?.cancel()
    }
    
    public mutating func enqueue(onResponse: @Sendable @escaping (Response) -> Void, onFailure: @Sendable @escaping (Error) -> Void) {
        self.onResponse = onResponse
        self.onFailure = onFailure
        request?.resume()
    }
}

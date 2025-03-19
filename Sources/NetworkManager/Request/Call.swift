    public struct Call<Response> {
        var request: Request? = nil
        private(set) var onResponse: ((Response) -> Void)? = nil
        private(set) var onFailure: ((Error) -> Void)? = nil
        
        public init() {
            
        }
        
        public func cancel() {
            request?.cancel()
        }
        
        public mutating func enqueue(onResponse: @escaping (Response) -> Void, onFailure: @escaping (Error) -> Void) {
            self.onResponse = onResponse
            self.onFailure = onFailure
            request?.resume()
        }
    }

struct AlamofireRequest: NetworkManager.Request {
    private let request: DataRequest
    
    init(request: DataRequest) {
        self.request = request
    }
    
    func resume() {
        request.resume()
    }
    
    func cancel() {
        request.cancel()
    }
}

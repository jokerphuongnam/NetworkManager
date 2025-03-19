public protocol Request: Sendable {
    func resume()
    func cancel()
}

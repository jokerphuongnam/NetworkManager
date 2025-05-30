public enum ErrorStatus: Sendable {
    case notDecodable
    case notEncodable
    case releasedSelf
    case releasedCall
}

public struct NMError: Error {
    let status: ErrorStatus
    let message: String
    
    public init(status: ErrorStatus, message: String) {
        self.status = status
        self.message = message
    }
}

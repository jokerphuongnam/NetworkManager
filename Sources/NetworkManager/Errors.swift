public enum ErrorStatus {
    case notDecodable
    case notEncodable
    case releasedSelf
    case releasedCall
}

public struct NMError: Error, @unchecked Sendable {
    let status: ErrorStatus
    let message: String
    
    public init(status: ErrorStatus, message: String) {
        self.status = status
        self.message = message
    }
}

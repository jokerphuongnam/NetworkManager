public enum CallAdapterType: String {
    case rxSwift = "RxSwift"
    case combine = "Combine"
    
    public init?(rawValue: String) {
        switch rawValue {
        case "rxSwift":
            self = .rxSwift
        case "combine":
            self = .combine
        default:
            return nil
        }
    }
}

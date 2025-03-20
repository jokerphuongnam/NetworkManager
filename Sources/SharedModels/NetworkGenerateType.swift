public enum NetworkGenerateType {
    case `class`, `actor`, `struct`
    
    public var swiftString: String {
        switch self {
        case .class:
            return "final class"
        case .actor:
            return "final actor"
        case .struct:
            return "struct"
        }
    }
    
    public var isRefType: Bool {
        switch self {
        case .class, .actor:
            return true
        case .struct:
            return false
        }
    }
}

public enum NetworkGenerateType {
    case `class`, `actor`, `struct`
    
    var swiftString: String {
        switch self {
        case .class:
            return "final class"
        case .actor:
            return "final actor"
        case .struct:
            return "struct"
        }
    }
}

//@attached(memberAttribute)
//public macro Path() = #externalMacro(module: "NetworkManagerMacros", type: "ParamMacro")

//@attached(memberAttribute)
//public macro Query() = #externalMacro(module: "NetworkManagerMacros", type: "ParamMacro")

public typealias Path<T> = Param<T>
public typealias Query<T> = Param<T>
public typealias Header = Param<String>

public struct Param<T> {
    public let value: T

    init(_ value: T) {
        self.value = value
    }
}

extension Param: ExpressibleByStringLiteral, ExpressibleByExtendedGraphemeClusterLiteral, ExpressibleByUnicodeScalarLiteral where T == String {
    public init(stringLiteral value: StringLiteralType) {
        self.value = value
    }
    
    public init(extendedGraphemeClusterLiteral value: ExtendedGraphemeClusterLiteralType) {
        self.value = value
    }
    
    public init(unicodeScalarLiteral value: UnicodeScalarLiteralType) {
        self.value = value
    }
}

extension Param: ExpressibleByIntegerLiteral where T == Int {
    public init(integerLiteral value: IntegerLiteralType) {
        self.value = value
    }
}

extension Param: ExpressibleByFloatLiteral where T == Double {
    public init(floatLiteral value: FloatLiteralType) {
        self.value = value
    }
}

extension Param: ExpressibleByBooleanLiteral where T == Bool {
    public init(booleanLiteral value: BooleanLiteralType) {
        self.value = value
    }
}

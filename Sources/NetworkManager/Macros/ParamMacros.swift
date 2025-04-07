//@attached(memberAttribute)
//public macro Path() = #externalMacro(module: "NetworkManagerMacros", type: "ParamMacro")

//@attached(memberAttribute)
//public macro Query() = #externalMacro(module: "NetworkManagerMacros", type: "ParamMacro")

public typealias Path<T> = Param<T>
public typealias Query<T> = Param<T>
public typealias Header = Param<String>

public struct Param<T>: @unchecked Sendable {
    public let value: T

    init(_ value: T) {
        self.value = value
    }
}

// MARK: String type
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


// MARK: - Integer
extension Param: ExpressibleByIntegerLiteral where T: FixedWidthInteger {
    public init(integerLiteral value: IntegerLiteralType) {
        self.value = T(value)
    }
}

// MARK: - Floating-point types
extension Param: ExpressibleByFloatLiteral where T: _ExpressibleByBuiltinFloatLiteral {
    public init(floatLiteral value: T) {
        self.value = value
    }
}

@available(watchOS 7.0, *)
@available(tvOS 14.0, *)
@available(iOS 14.0, *)
@available(macOS 11.0, *)
extension Param where T == Float16 {
    public init(integerLiteral value: Int64) {
        self.value = T(value)
    }
}

extension Param where T == Float32 {
    public init(integerLiteral value: Int64) {
        self.value = T(value)
    }
}

extension Param where T == Float64 {
    public init(integerLiteral value: Int64) {
        self.value = T(value)
    }
}

// MARK: Boolean type
extension Param: ExpressibleByBooleanLiteral where T == Bool {
    public init(booleanLiteral value: BooleanLiteralType) {
        self.value = value
    }
}

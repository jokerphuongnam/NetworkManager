import Foundation

public struct JSONDecodableConverterFactory: ConverterFactory {
    private let decodable: JSONDecoder
    private let encodable: JSONEncoder
    
    public init(decodable: JSONDecoder, encodable: JSONEncoder) {
        self.decodable = decodable
        self.encodable = encodable
    }
    
    public init() {
        self.decodable = JSONDecoder()
        self.encodable = JSONEncoder()
    }
    
    public func responseConverter<T>(data: Data) throws -> T {
        guard let type = T.self as? Decodable.Type else {
            throw NMError(status: .notDecodable, message: "\(String(describing: T.self)) need conform to Decodable")
        }
        return try decodable.decode(type, from: data) as! T
    }
    
    public func requestBodyConverter<T>(body: T) throws -> Data {
        guard let encodableBody = body as? Encodable else {
            throw NMError(status: .notEncodable, message: "\(String(describing: T.self)) need conform to Encodable")
        }
        return try encodable.encode(encodableBody)
    }
}

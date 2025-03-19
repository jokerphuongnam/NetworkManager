import Foundation

public protocol ConverterFactory: Sendable {
    func responseConverter<T>(data: Data) throws -> T
    func requestBodyConverter<T>(body: T) throws -> Data
}

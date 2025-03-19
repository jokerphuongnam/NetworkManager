import Foundation

public protocol ConverterFactory {
    func responseConverter<T>(data: Data) throws -> T
    func requestBodyConverter<T>(body: T) throws -> Data
}

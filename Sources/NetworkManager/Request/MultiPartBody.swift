import Foundation

public struct MultiPartBody: Sendable {
    public let name: String
    public let mineType: String
    public let content: Data
    
    public init(name: String, mineType: String, content: Data) {
        self.name = name
        self.mineType = mineType
        self.content = content
    }
}

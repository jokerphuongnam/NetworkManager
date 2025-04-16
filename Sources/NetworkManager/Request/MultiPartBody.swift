import Foundation

public struct MultiPartBody: Sendable {
    public let name: String
    public let mimeType: String
    public let content: Data
    
    public init(name: String, mimeType: String, content: Data) {
        self.name = name
        self.mimeType = mimeType
        self.content = content
    }
}

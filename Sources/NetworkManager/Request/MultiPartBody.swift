import Foundation

public struct MultiPartBody: Sendable {
    let name: String
    let mineType: String
    let content: Data
    
    public init(name: String, mineType: String, content: Data) {
        self.name = name
        self.mineType = mineType
        self.content = content
    }
}

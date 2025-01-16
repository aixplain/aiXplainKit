import Foundation

public struct FunctionListResponse: Codable {
    public let results: [Function]
}

public struct FunctionResponse: Codable {
    public let id: String
    public let name: String
}

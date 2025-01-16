import Foundation

public struct FunctionListResponse: Codable {
    public let results: [Function]
}

public struct FunctionResponse: Codable {
    let id: String
    let name: String
}

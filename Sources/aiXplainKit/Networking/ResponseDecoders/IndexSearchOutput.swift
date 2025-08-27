// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let indexSearchOutput = try? JSONDecoder().decode(IndexSearchOutput.self, from: jsonData)

import Foundation

// MARK: - IndexSearchOutput
public struct IndexSearchOutput: Codable {
    public let details: [Detail]
    public let status: String
    public let completed: Bool
    public let data: String
    public let runTime, usedCredits: Double

    public init(details: [Detail], status: String, completed: Bool, data: String, runTime: Double, usedCredits: Double) {
        self.details = details
        self.status = status
        self.completed = completed
        self.data = data
        self.runTime = runTime
        self.usedCredits = usedCredits
    }
}

// MARK: - Detail
public struct Detail: Codable {
    public let score: Double
    public let data, document: String
    public let metadata: [String:String]

    public init(score: Double, data: String, document: String, metadata: [String:String]) {
        self.score = score
        self.data = data
        self.document = document
        self.metadata = metadata
    }
}

// MARK: - Metadata
public struct Metadata: Codable {

    public init() {
    }
}

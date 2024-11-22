//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 20/11/24.
//

import Foundation

/// Extends `Dictionary` to conform to the `AgentInputable` protocol when both keys and values meet specific criteria.
///
/// This allows dictionaries with `String` keys and `AgentInputable` values to be used as inputs for agents,
/// enabling them to process structured data such as multiple file URLs or text inputs.
extension Dictionary: AgentInputable where Key == String, Value == AgentInputable {

    /// Generates a JSON payload for an agent execution using the dictionary as input.
    ///
    /// The method processes each key-value pair in the dictionary. For values that are URLs, it uploads the file
    /// to S3 if necessary and includes the resulting URL in the payload. String values are added directly.
    ///
    /// - Parameters:
    ///   - using: The `AgentRunParameters` containing additional configuration for the agent execution.
    ///   - withID: An optional session ID to include in the payload.
    /// - Returns: A `Data` object containing the JSON representation of the payload.
    /// - Throws:
    ///   - `AgentsError.typeNotRecognizedWhileCreatingACombinedInput` if a value in the dictionary is not supported.
    ///   - `AgentsError.inputEncodingError` if the payload cannot be serialized to JSON.
    ///   - Errors related to file upload for URL values.
    ///
    /// # Example
    /// ```swift
    /// let input: [String: AgentInputable] = [
    ///     "text": "Hello, world!",
    ///     "file": URL(fileURLWithPath: "/path/to/file.txt")
    /// ]
    /// let parameters = AgentRunParameters()
    /// do {
    ///     let payload = try await input.generateInputPayloadForAgent(using: parameters, withID: "session-123")
    ///     print(String(data: payload, encoding: .utf8)!) // JSON representation of the payload
    /// } catch {
    ///     print("Failed to generate input payload: \(error)")
    /// }
    /// ```
    public func generateInputPayloadForAgent(using: AgentRunParameters, withID: String?) async throws -> Data {
        var parsedSequence: [String: String] = [:]
        let fileUploadManager = FileUploadManager()

        for (_, keyValuePair) in self.enumerated() {
            let (key, value) = keyValuePair

            switch value {
            case let url as URL:
                let remoteURL = try await fileUploadManager.uploadDataIfNeedIt(from: url)
                parsedSequence.updateValue(remoteURL.absoluteString, forKey: key)
            case let string as String:
                parsedSequence.updateValue(string, forKey: key)
            default:
                throw AgentsError.typeNotRecognizedWhileCreatingACombinedInput
            }
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parsedSequence, options: []) else {
            throw AgentsError.inputEncodingError
        }

        return jsonData
    }
}

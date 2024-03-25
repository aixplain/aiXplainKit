//
//  File.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 22/03/24.
//

import Foundation

extension Dictionary: PipelineInput where Key == String, Value == PipelineInput {

    /// Generates an input payload for the pipeline based on the dictionary's key-value pairs.
    ///
    /// This method iterates through the dictionary's key-value pairs and constructs a payload that can be used as input for the pipeline. If the value is a URL, it uploads the data and includes the remote URL in the payload. If the value is a string, it includes the string directly in the payload. Other types are not supported and will result in an error.
    ///
    /// - Returns: The generated input payload as `Data`.
    /// - Throws: `PipelineError.typeNotRecognizedWhileCreatingACombinedInput` if an unsupported value type is encountered.
    ///           `FileUploadError` if an error occurs during file upload.
    ///           `PipelineError.inputEncodingError` if an error occurs during JSON encoding.
    public func generateInputPayloadForPipeline() async throws -> Data {
        var valuesSequence: [[String: String]] = []
        let fileUploadManager = FileUploadManager()

        for (_, keyValuePair) in self.enumerated() {
            let (key, value) = keyValuePair
            var valuesDict: [String: String] = [:]

            switch value {
            case let url as URL:
                let remoteURL = try await fileUploadManager.uploadDataIfNeedIt(from: url)
                valuesDict.updateValue(remoteURL.absoluteString, forKey: "value")
            case let string as String:
                valuesDict.updateValue(string, forKey: "value")
            default:
                throw PipelineError.typeNotRecognizedWhileCreatingACombinedInput
            }

            valuesDict.updateValue(key, forKey: "nodeId")
            valuesSequence.append(valuesDict)
        }

        let ouputDict = ["data": valuesSequence]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: ouputDict, options: []) else {
            throw PipelineError.inputEncodingError
        }

        return jsonData
    }
}

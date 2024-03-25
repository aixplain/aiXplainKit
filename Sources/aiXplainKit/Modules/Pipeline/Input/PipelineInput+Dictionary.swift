//
//  File.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 22/03/24.
//

import Foundation

extension Dictionary: PipelineInput where Key == String, Value == PipelineInput {

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
                throw PipelineError.typeNotRecongnizedWhileCreatingACombinedInput
            }

            valuesDict.updateValue(key, forKey: "nodeId")
            valuesSequence.append(valuesDict)
        }

        let ouputDict = ["data": valuesSequence]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: ouputDict, options: []) else {
            // TODO: Instead of returning an empty Data instance, it's better to throw an error or provide a fallback value
            return Data()
        }

        return jsonData
    }
}

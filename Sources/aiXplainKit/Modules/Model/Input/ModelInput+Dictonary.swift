/*
 AiXplainKit Library.
 ---
 
 aiXplain SDK enables Swift programmers to add AI functions
 to their software.
 
 Copyright 2024 The aiXplain SDK authors
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 AUTHOR: João Pedro Maia
 */

import Foundation

extension Dictionary: ModelInput where Key == String, Value == ModelInput {
    public func generateInputPayloadForModel() async throws -> Data {
        var parsedSequence: [String:String] = [:]
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
                throw PipelineError.typeNotRecognizedWhileCreatingACombinedInput
            }
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: parsedSequence, options: []) else {
            throw PipelineError.inputEncodingError
        }

        return jsonData
    }
}

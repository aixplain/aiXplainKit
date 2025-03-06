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

/// An extension that conforms `URL` to the `PipelineInput` protocol.
extension URL: PipelineInput {

    /// Generates an input payload data for the pipeline.
    ///
    /// - Returns: An empty `Data` instance.
    public func generateInputPayloadForPipeline() async throws -> Data {
        var payload = ["data": self.absoluteString]

        switch self.absoluteString {
        case let link where link.starts(with: "s3://"):
            break
        case let link where link.starts(with: "http://"):
            break
        case let link where link.starts(with: "https://"):
            break
        default:
            let fileManager = FileUploadManager()
            let s3URL = try await fileManager.uploadFile(at: self)

            payload.updateValue(s3URL.absoluteString.removingPercentEncoding ?? s3URL.absoluteString, forKey: "data")
        }

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            throw ModelError.failToGenerateAFilePayload(error: String(describing: payload))
        }

        return jsonData

    }
}

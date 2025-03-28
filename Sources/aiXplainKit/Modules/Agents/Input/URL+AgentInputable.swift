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

/// Extends the `URL` type to conform to the `AgentInputable` protocol.
///
/// This allows URLs to be used as inputs for agents, enabling them to handle file paths, HTTP links,
/// or S3 URIs dynamically. It includes functionality for generating payloads and handling uploads to S3 storage.
extension URL: AgentInputable {

    /// Generates a JSON payload for an agent execution using the URL as input.
    ///
    /// If the URL is a local file, it uploads the file to S3 and includes the resulting URL in the payload.
    /// URLs that are already HTTP/HTTPS or S3 paths are directly used without modification.
    ///
    /// - Parameters:
    ///   - using: The `AgentRunParameters` containing additional configuration for the agent execution.
    ///   - id: An optional session ID to include in the payload.
    /// - Returns: A `Data` object containing the JSON representation of the payload.
    /// - Throws:
    ///   - `ModelError.failToGenerateAFilePayload` if the payload cannot be serialized to JSON.
    ///   - Errors related to file upload if the URL is a local file.
    ///
    /// # Example
    /// ```swift
    /// let fileURL = URL(fileURLWithPath: "/path/to/file.txt")
    /// let parameters = AgentRunParameters()
    /// let payload = try await fileURL.generateInputPayloadForAgent(using: parameters, withID: "session-123")
    /// print(String(data: payload, encoding: .utf8)!) // JSON representation of the payload
    /// ```
    public func generateInputPayloadForAgent(using: AgentRunParameters, withID id: String? = nil) async throws -> Data {
        var payload = ["query": self.absoluteString]

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
    
    /// Uploads the file at the current URL to S3 if it is a local file path.
    ///
    /// This method checks the type of URL and performs the upload only if the URL is a local file.
    /// URLs that are already S3, HTTP, or HTTPS links are returned as-is.
    ///
    /// - Returns: A `URL` pointing to the uploaded file on S3, or the original URL if no upload is needed.
    /// - Throws: Errors related to file upload if the URL is a local file.
    ///
    /// # Example
    /// ```swift
    /// let fileURL = URL(fileURLWithPath: "/path/to/local/file.txt")
    /// do {
    ///     let s3URL = try await fileURL.uploadToS3IfNeedIt()
    ///     print("S3 URL: \(s3URL)")
    /// } catch {
    ///     print("Failed to upload file: \(error)")
    /// }
    /// ```
    func uploadToS3IfNeedIt() async throws -> URL {
        switch self.absoluteString {
        case let link where link.starts(with: "s3://"):
            break
        case let link where link.starts(with: "http://"):
            break
        case let link where link.starts(with: "https://"):
            break
        default:
            let fileManager = FileUploadManager()
            return try await fileManager.uploadFile(at: self)
        }
        return self
    }
}

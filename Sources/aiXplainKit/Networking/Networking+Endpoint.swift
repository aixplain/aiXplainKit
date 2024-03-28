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

/// This extension adds the default endpoints called by the SDK
extension Networking {

    /// Represents the different endpoints used by the SDK
    enum Endpoint {
        /// Represents the endpoint for retrieving a specific model
        case model(modelIdentifier: String)

        /// Represents the endpoint for retrieving functions
        case functionEndpoint

        /// Represents the endpoint for file upload
        /// - parameter isTemporary: A boolean value indicating whether the upload is temporary or not
        case fileUpload(isTemporary: Bool)

        /// Represents the endpoint for executing a specific model
        /// - parameter modelIdentifier: The identifier of the model to be executed
        case execute(modelIdentifier: String)

        case pipelines(pipelineIdentifier: String)

        case pipelineRun(pipelineIdentifier: String)

        /// The path for the endpoint
        var path: String {
            switch self {
            case .model(let modelIdentifier):
                return "/sdk/models/\(modelIdentifier)"
            case .functionEndpoint:
                return "/sdk/functions"
            case .fileUpload(let isTemporary):
                let temporaryUploadPath = "/sdk/file/upload/temp-url"
                let permanentUploadPath = "/sdk/file/upload-url"
                return isTemporary ? temporaryUploadPath : permanentUploadPath
            case .execute(let modelIdentifier):
                return "/execute/\(modelIdentifier)"
            case .pipelines(pipelineIdentifier: let pipelineIdentifier):
                return "/sdk/pipelines/\(pipelineIdentifier)"
            case .pipelineRun(pipelineIdentifier: let pipelineIdentifier):
                return "/assets/pipeline/execution/run/\(pipelineIdentifier)"
            }
        }
    }
}

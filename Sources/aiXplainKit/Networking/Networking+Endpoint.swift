//
//  Networking+Endpoint.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 08/03/24.
//

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

        /// The path for the endpoint
        var path: String {
            switch self {
            case .model(let modelIdentifier):
                return "/sdk/models/\(modelIdentifier)"
            case .functionEndpoint:
                return "/sdk/functions"
            case .fileUpload(let isTemporary):
                let temporaryUploadPath = "sdk/file/upload/temp-url"
                let permanentUploadPath = "sdk/file/upload-url"
                return isTemporary ? temporaryUploadPath : permanentUploadPath
            case .execute(let modelIdentifier):
                return "/execute/\(modelIdentifier)"
            }
        }
    }
}

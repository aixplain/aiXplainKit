//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

/// Represents errors that can occur during file operations.
enum FileError: Error {
    /// The file size exceeds the maximum allowed limit.
    case fileSizeExceedsLimit

    /// An error occurred while generating the payload for obtaining the pre-signed URL for uploading the file.
    case payloadGenerationFailed(description: String)

    /// Failed to obtain the pre-signed URL for uploading the file to S3.
    case couldNotGetTheS3PreSignedURL

    /// The bucket name for the S3 upload was not found.
    case bucketNameNotFound

    /// A description of the error.
    var errorDescription: String {
        switch self {
        case .fileSizeExceedsLimit:
            return "The file size exceeds the maximum allowed limit."
        case .payloadGenerationFailed(let description):
            return "An error occurred while generating the payload for obtaining the pre-signed URL: \(description)"
        case .couldNotGetTheS3PreSignedURL:
            return "Failed to obtain the pre-signed URL for uploading the file to S3."
        case .bucketNameNotFound:
            return "The bucket name for the S3 upload was not found."
        }
    }
}

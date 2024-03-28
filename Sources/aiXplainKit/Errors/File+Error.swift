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

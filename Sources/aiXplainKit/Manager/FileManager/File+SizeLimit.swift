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

extension FileUploadManager {

    /// Defines the file size limit for different types of files based on their MIME types.
    enum FileSizeLimit: String {
        /// Represents audio files.
        case audio
        /// Represents application files (e.g., documents, executables).
        case application
        /// Represents video files.
        case video
        /// Represents image files.
        case image
        /// Represents other types of files.
        case other

        /// The maximum file size limit in bytes for the given file type.
        var limit: Int {
            let megabyte25 = 26214400
            let megabyte50 = 52428800
            let megabyte300 = 314572800

            switch self {
            case .audio:
                return megabyte50
            case .application:
                return megabyte25
            case .video:
                return megabyte300
            case .image:
                return megabyte25
            case .other:
                return megabyte50
            }
        }

        /// Checks if the file at the given URL is under the size limit based on its MIME type.
            ///
            /// This function uses the `mimeType` function to determine the MIME type of the file and compares its size with the corresponding limit defined in the `FileSizeLimit` enum.
            ///
            /// - Parameter url: The URL of the file to check.
            /// - Throws: An `NSError` if the file size exceeds the limit for its MIME type.
            static func check(fileAt fileURL: URL) throws -> Bool {
                let mimeType: String = fileURL.mimeType()
                var fileSizeLimit: FileSizeLimit

                if let mimeTypePart = mimeType.split(separator: "/").first,
                   let fileSizeLimitCase = FileSizeLimit(rawValue: String(mimeTypePart)) {
                    fileSizeLimit = fileSizeLimitCase
                } else {
                    fileSizeLimit = .other
                }

                let filePath = fileURL.path
                let fileSize = try FileManager.default.attributesOfItem(atPath: filePath)[.size] as? Int ?? 0

                if fileSize > fileSizeLimit.limit {
                    return false
                } else {
                    return true
                }
            }
    }
}

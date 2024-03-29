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
 */

import Foundation
import UniformTypeIdentifiers
extension URL {
    /**
     Returns the MIME type associated with the file at the URL's path.

     The `mimeType()` method returns a `String` representing the MIME type of the file at the URL's path. If the file extension is recognized by the system, the method returns the preferred MIME type for that extension. If the file extension is not recognized, the method returns the default MIME type `"application/octet-stream"`.

     MIME types, or Multipurpose Internet Mail Extensions, are used to identify the type of data being transmitted over the Internet. They are especially important when transferring files, as they allow recipient applications to determine how to handle the incoming data.

     - Semantics:
         - If the URL's path extension is recognized by the system, the method returns the preferred MIME type for that extension.
         - If the URL's path extension is not recognized, the method returns `"application/octet-stream"`.
         - If the URL does not have a path extension, the method returns `"application/octet-stream"`.

     - Returns: The MIME type associated with the file at the URL's path.
     
     - Examples:
         ```swift
         let fileURL = URL(fileURLWithPath: "/path/to/file.pdf")
         let mimeType = fileURL.mimeType() // Returns "application/pdf"
         ```
         In this example, the `mimeType()` method returns `"application/pdf"` because the `.pdf` extension is recognized by the system, and the preferred MIME type for PDF files is `"application/pdf"`.

         ```swift
         let fileURL = URL(fileURLWithPath: "/path/to/file.unknown")
         let mimeType = fileURL.mimeType() // Returns "application/octet-stream"
         ```
         In this example, the `mimeType()` method returns `"application/octet-stream"` because the `.unknown` extension is not recognized by the system, and `"application/octet-stream"` is the default MIME type for unknown file types.
     */
    public func mimeType() -> String {
        if let mimeType = UTType(filenameExtension: self.pathExtension)?.preferredMIMEType {
            return mimeType
        } else {
            return "application/octet-stream"
        }
    }
}

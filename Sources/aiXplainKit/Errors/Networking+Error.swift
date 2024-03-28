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

/// This enum represents different types of errors that can occur during network operations.
enum NetworkingError: Error, Equatable {

   /// Indicates that the HTTP response received was invalid.
   case invalidHttpResponse

   /// Indicates that an invalid HTTP status code was received from the network request.
   /// The associated value stores the specific status code.
   case invalidStatusCode(statusCode: Int)

   /// Indicates that the provided URL is malformed.
   /// The associated value stores the malformed URL string.
   case invalidURL(url: String?)

   /// Indicates that the maximum number of retries for the network request has been reached.
   case maxRetryReached

   /// A localized description of the error.
   var localizedDescription: String {
       switch self {
       case .invalidStatusCode(let statusCode):
           return "Invalid status code received: \(statusCode)"
       case .invalidURL(let url):
           guard let urlString = url else { return "Invalid URL." }
           return "The provided URL is malformed: \(urlString)"
       case .invalidHttpResponse:
           return "The provided HTTP response is invalid"
       case .maxRetryReached:
           return "The maximum number of retries for the network request has been reached."
       }
   }
}

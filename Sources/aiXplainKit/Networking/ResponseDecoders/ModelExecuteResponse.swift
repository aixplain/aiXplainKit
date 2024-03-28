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

/// Decodes the response when running a model making a API call to  `MODELS_RUN_URL
internal struct ModelExecuteResponse: Codable {
    let completed: Bool?
    let data: String?
    let requestId: String?

    var pollingURL: URL? {
        URL(string: self.data ?? "")
    }

    enum CodingKeys: String, CodingKey {
        case completed
        case data
        case requestId
    }
}

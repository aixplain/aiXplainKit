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
/// An extension that conforms `String` to the `ModelInput` protocol.
extension String: ModelInput {
    /// Generates an input payload data for the model by wrapping the string value in a dictionary with the key "data".
    ///
    /// - Returns: The input payload data for the model.
    public func generateInputPayloadForModel() -> Data {
        let payload = ["data": self]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            return Data()
        }

        return jsonData
    }
}

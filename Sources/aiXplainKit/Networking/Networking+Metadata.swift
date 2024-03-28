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

extension Networking {
    /// Generates the headers required for making API calls.
        ///
        /// This function constructs the necessary headers by retrieving the AI Explain API key and the Team API key from the `APIKeyManager` class. If both keys are available, it returns a dictionary containing the headers with the respective keys and the "Content-Type" header set to "application/json".
        ///
        /// - Returns: A dictionary containing the headers required for API calls.
        /// - Throws: `ModelError.missingAPIKey` if neither API key is available.
    func buildHeader() throws -> [String: String] {
        var headers: [String: String]?
        if let aiXplainKey = APIKeyManager.shared.AIXPLAIN_API_KEY {
            headers =  ["x-aixplain-key": "\(aiXplainKey)", "Content-Type": "application/json"]
        }

        if let teamKey = APIKeyManager.shared.TEAM_API_KEY {
            headers =  ["Authorization": "Token \(teamKey)", "Content-Type": "application/json"]
        }

        guard let headers else {
            throw ModelError.missingAPIKey
        }

        return headers
    }

    /// Builds the URL for a specific endpoint.
        ///
        /// This function constructs the URL for a given `Endpoint` by retrieving the base URL from the `APIKeyManager` class and appending the endpoint's path to it.
        ///
        /// - Parameter endpoint: The `Endpoint` for which the URL should be constructed.
        /// - Returns: The constructed URL for the specified endpoint, or `nil` if the base URL is missing.
        /// - Throws: `ModelError.missingBackendURL` if the base URL is not available.
    func buildUrl(for endpoint: Endpoint) throws -> URL? {

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }
        return URL(string: url.absoluteString + endpoint.path)
    }
}

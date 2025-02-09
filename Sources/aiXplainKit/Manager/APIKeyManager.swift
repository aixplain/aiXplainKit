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

/**
 A singleton class responsible for managing API keys used by the application.
 
 The `APIKeyManager` class provides a centralized place to store and retrieve various API keys required by the application. It supports loading API keys from environment variables and manually setting them in code.
 
 - Important: Ensure that you securely store and manage your API keys. Avoid committing API keys to version control systems or distributing them with your application.
 
 ## Setting the keys

 An example of how to use the `APIKeyManager` to retrieve and set API keys.
 
 To set the API keys using Xcode environment variables, follow these steps:
 
 1. In Xcode, select your project in the Project Navigator.
 2. Select your target, then click the "Info" tab.
 3. Under the "Configurations" section, click the "+" button in the bottom-left corner.
 4. In the newly added row, set the "Name" to the desired API key name (e.g., "TEAM_API_KEY") and the "Value" to your API key.
 5. Repeat step 4 for each API key you need to set.
 
 With the environment variables set, the `APIKeyManager` will automatically load and use the API keys from the corresponding environment variables.
 
 You can also set the API keys directly in code if needed:
 
 ```swift
 AiXplainKit.shared.keyManager.TEAM_API_KEY = "<Your Key>"
```
 
 ###
 

 */
public final class APIKeyManager {

    /// The shared instance of the APIKeyManager.
    public static var shared = APIKeyManager()

    /// The base URL for the backend API.
    public var BACKEND_URL: URL?

    /// The URL for the models run API endpoint. 
    public var MODELS_RUN_URL: URL?

    public var TEAM_API_KEY: String?
    public var AIXPLAIN_API_KEY: String?
    public var PIPELINE_API_KEY: String?
    public var MODEL_API_KEY: String?

    /// The API token for Hugging Face (optional).
    public var HF_TOKEN: String?

    /// Initializes an APIKeyManager with nil values for its properties.
    internal init() {
        loadAPIKeysFromProcessInfo()
    }

    /// Fetches API keys and URLs from ProcessInfo and populates the relevant properties.
    private func loadAPIKeysFromProcessInfo() {
        // Load URLs from environment, falling back to defaults if not found
        if let backendURLString = ProcessInfo.processInfo.environment["BACKEND_URL"],
           let url = URL(string: backendURLString) {
            self.BACKEND_URL = url
        } else {
            self.BACKEND_URL = URL(string: "https://platform-api.aixplain.com")
        }

        if let modelsURLString = ProcessInfo.processInfo.environment["MODELS_RUN_URL"],
           let url = URL(string: modelsURLString) {
            self.MODELS_RUN_URL = url
        } else {
            self.MODELS_RUN_URL = URL(string: "https://models.aixplain.com/api/v1/execute/")
        }

        // Load API keys
        self.TEAM_API_KEY = ProcessInfo.processInfo.environment["TEAM_API_KEY"]
        self.AIXPLAIN_API_KEY = ProcessInfo.processInfo.environment["AIXPLAIN_API_KEY"]
        self.PIPELINE_API_KEY = ProcessInfo.processInfo.environment["PIPELINE_API_KEY"]
        self.MODEL_API_KEY = ProcessInfo.processInfo.environment["MODEL_API_KEY"]

        self.HF_TOKEN = ProcessInfo.processInfo.environment["HF_TOKEN"]
    }

    /// Clean all keys provided
    public func clear() {
        self.TEAM_API_KEY = nil
        self.AIXPLAIN_API_KEY = nil
        self.PIPELINE_API_KEY = nil
        self.MODEL_API_KEY = nil

        self.HF_TOKEN = nil
    }

}

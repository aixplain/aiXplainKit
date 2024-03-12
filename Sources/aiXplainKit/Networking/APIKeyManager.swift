//
//  APIKeyManager.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 05/03/24.
//

import Foundation

/// A singleton class responsible for managing API keys used by the application.
public final class APIKeyManager {

    /// The shared instance of the APIKeyManager.
    public static var shared = APIKeyManager()

    /// The base URL for the backend API.
    public var BACKEND_URL: URL? = URL(string: "https://platform-api.aixplain.com")

    /// The URL for the models run API endpoint.
    public var MODELS_RUN_URL: URL? = URL(string: "https://models.aixplain.com/api/v1/execute/")

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

    /// Fetches API keys from ProcessInfo and populates the relevant properties.
    private func loadAPIKeysFromProcessInfo() {

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

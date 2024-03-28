//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 27/03/24.
//

import Foundation
import aiXplainKit

internal extension APIKeyManager {
    func reload() {
        self.BACKEND_URL =  URL(string: "https://platform-api.aixplain.com")
        self.MODELS_RUN_URL = URL(string: "https://models.aixplain.com/api/v1/execute/")
        self.TEAM_API_KEY = ProcessInfo.processInfo.environment["TEAM_API_KEY"]
        self.AIXPLAIN_API_KEY = ProcessInfo.processInfo.environment["AIXPLAIN_API_KEY"]
        self.PIPELINE_API_KEY = ProcessInfo.processInfo.environment["PIPELINE_API_KEY"]
        self.MODEL_API_KEY = ProcessInfo.processInfo.environment["MODEL_API_KEY"]
        self.HF_TOKEN = ProcessInfo.processInfo.environment["HF_TOKEN"]

    }
}

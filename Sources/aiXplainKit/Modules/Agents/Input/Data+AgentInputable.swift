//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 18/11/24.
//

import Foundation

extension Data:AgentInputable {
    public func generateInputPayloadForAgent(using:AgentRunParameters,withID:String? = nil) async throws -> Data {
        return self
    }
}

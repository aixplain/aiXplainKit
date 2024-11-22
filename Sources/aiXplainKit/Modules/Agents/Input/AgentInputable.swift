//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 18/11/24.
//

import Foundation
public protocol AgentInputable{
    func generateInputPayloadForAgent(using:AgentRunParameters, withID:String?) async throws -> Data
}

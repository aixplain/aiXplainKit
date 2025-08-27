//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 13/05/25.
//

import Foundation

extension Record:ModelInput {
    public func generateInputPayloadForModel() async throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

extension Array:ModelInput where Element == Record {
    public func generateInputPayloadForModel() async throws -> Data {
        return try JSONEncoder().encode(self)
    }
}

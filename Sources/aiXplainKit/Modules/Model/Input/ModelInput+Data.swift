//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 13/05/25.
//

import Foundation
extension Data: ModelInput{
    public func generateInputPayloadForModel() async throws -> Data {
        return self 
    }
}

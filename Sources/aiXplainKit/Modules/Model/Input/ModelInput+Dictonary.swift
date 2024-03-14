//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 14/03/24.
//

import Foundation

extension Dictionary: ModelInput where Key == String, Value == Any {
    public func generateInputPayloadForModel() async throws -> Data {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: self, options: []) else {
            return Data()
        }
        return jsonData
    }
}

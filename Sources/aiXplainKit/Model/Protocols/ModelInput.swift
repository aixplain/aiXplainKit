//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 11/03/24.
//

import Foundation

//TODO: Documentation
public protocol ModelInput{
    func generateInputPayloadForModel() -> Data
}

//MARK: Foundation Types as Input

extension String:ModelInput{
    public func generateInputPayloadForModel() -> Data {
        let payload = ["data": self]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            //TODO: Handle error case if JSON serialization fails
            return Data()
        }
        
        return jsonData
    }
}


extension URL:ModelInput{
    public func generateInputPayloadForModel() -> Data {
        return Data()
    }
}

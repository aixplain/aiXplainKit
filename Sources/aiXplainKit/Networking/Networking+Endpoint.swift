//
//  Networking+Endpoint.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 08/03/24.
//

import Foundation

///This extension adds the default endpoints called by the SDK
extension Networking{
    //TODO: Documentation
    enum Endpoint{
        case model(modelID:String)
        case function
        case fileUpload(istemporary:Bool)
        case execute(modelID:String)
        
        var path:String{
            switch self {
            case .model(let modelID):
                return "/sdk/models/\(modelID)"
            case .function:
                return "/sdk/functions"
            case .fileUpload(istemporary: let istemporary):
                return istemporary ? "sdk/file/upload/temp-url" : "sdk/file/upload-url"
            case .execute(modelID: let modelID):
                return "/execute/" + modelID
            }
        }
    }
    
    
}

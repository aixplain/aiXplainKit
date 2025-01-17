//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 18/11/24.
//

import Foundation
struct AgentExecuteResponse:Decodable{
    let requestId:String
    let sessionId:String
    let data:String
    
    var maybeUrl:URL?{
        guard let url = URL(string: data) else{
            return nil
        }
        return url
    }
}

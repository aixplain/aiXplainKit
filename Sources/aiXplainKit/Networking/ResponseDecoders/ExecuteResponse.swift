//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation


/// Decodes the response when running a model making a API call to  `MODELS_RUN_URL
internal struct ExecuteResponse: Codable {
    let completed: Bool?
    let data: String?
    let requestId: String?
    
    var pollingURL:URL? {
        URL(string: self.data ?? "")
    }

    enum CodingKeys: String, CodingKey {
        case completed
        case data
        case requestId
    }
}

//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 19/03/24.
//

import Foundation

struct PipelineExecuteResponse: Codable {
    let url: URL?
    let status: String
    let batchMode: Bool
}

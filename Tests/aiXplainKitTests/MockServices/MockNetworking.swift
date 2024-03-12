//
//  MockNetworking.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 08/03/24.
//

import Foundation
@testable import aiXplainKit

final class MockNetworking:Networking{
    
    var getReturnValue:(Data, URLResponse) = (Data(), URLResponse())
    
    override func get(url: URL, headers: [String : String]) async throws -> (Data, URLResponse) {
        getReturnValue
    }
    
}

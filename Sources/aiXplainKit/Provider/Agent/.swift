//
//  File.swift
//  aiXplainKit
//
//  Created by Joao Maia on 27/08/25.
//

import Foundation

final public class AgentSessionProvider {
    static public func create() -> AgentSession {
        return AgentSession()
    }
}



struct AgentSelection {
    let timestamp: Date = .now()
    let sessionID: String = UUID().uuidString
}

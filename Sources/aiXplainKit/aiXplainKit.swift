// The Swift Programming Language
// https://docs.swift.org/swift-book
import Foundation
public final class AiXplainKit {
    public let keyManager = APIKeyManager.shared
    public static let shared = AiXplainKit()
    public var logLevel: ParrotLogger.LogSeverity = .info

}

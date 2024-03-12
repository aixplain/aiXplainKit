//
//  ParrotLogger
//

import Foundation

extension ParrotLogger {
    /// This code defines a Swift struct called LogEntry. It represents a single log entry,
    public struct LogEntry: Identifiable, Codable, Equatable {
        public var id: UUID = UUID()
        public let date: Date
        public let logLevel: LogSeverity
        public let category: String
        public let functionName: String
        public let content: String

        enum CodingKeys: String, CodingKey {
            case id
            case date
            case logLevel
            case category
            case functionName
            case content
        }

        public init(date: Date, logLevel: LogSeverity, category: String, functionName: String, content: String) {
            self.date = date
            self.logLevel = logLevel
            self.category = category
            self.functionName = functionName
            self.content = content
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(id, forKey: .id)
            try container.encode(date, forKey: .date)
            try container.encode(logLevel, forKey: .logLevel)
            try container.encode(category, forKey: .category)
            try container.encode(functionName, forKey: .functionName)
            try container.encode(content, forKey: .content)
        }

        public static func ==(lhs: ParrotLogger.LogEntry, rhs: ParrotLogger.LogEntry) -> Bool {
            return lhs.date == rhs.date &&
            lhs.logLevel == rhs.logLevel &&
            lhs.category == rhs.category &&
            lhs.functionName == rhs.functionName &&
            lhs.content == rhs.content
        }
    }
}

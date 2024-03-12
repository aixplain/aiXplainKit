//
//  ParrotLogger
//

import Foundation
import Combine

/// `ParrotLogger` is a logging utility class that provides a simple way to log messages with different log severities.
public class ParrotLogger: ObservableObject {

    public static let generalLogLevel: LogSeverity = AiXplainKit.shared.logLevel
    public var logLevel: LogSeverity

    public let category: String
    public let dateFormatter: DateFormatter

    static public private(set) var sessionEntries = [LogEntry]()

    @MainActor static public var latestEntry: LogEntry? { sessionEntries.last }
    @MainActor static public var newLogEntryPublisher = PassthroughSubject<Void, Never>()

    // MARK: - Initialization
    /// Initializes a new instance of ParrotLogger.
    /// - Parameters:
    ///   - logLevel: The minimum log level that this logger will print. If not provided, the logger will use the default log level for the given category or the general log level if no specific log level is defined for the category.
    ///   - category: The name of the category that this logger will log.
    ///   - dateFormatter: The date formatter used to format the timestamps in the log messages. If not provided, the logger will use the default date formatter.
    public init(
        logLevel: LogSeverity? = nil,
        category: String,
        dateFormatter: DateFormatter? = nil
    ) {
        self.category = category
        let logLevelForCategory = Self.getLogLevel(forCategory: category)
        if logLevel != nil && logLevelForCategory != nil {
            print("Log level specified on the \(category) LogHelper's initialization overriding the value from the environment variable.")
        }
        self.logLevel = logLevel ?? logLevelForCategory ?? Self.generalLogLevel
        self.dateFormatter = dateFormatter ?? Self.defaultDateformatter
    }

    // MARK: - Static helper methods
    private static var defaultDateformatter = {
        let dtf = DateFormatter()
        dtf.dateFormat = "HH:mm:ss.SS"
        return dtf
    }()

    /// This method retrieves the general log level from the environment variable LOG_LEVEL, and returns the corresponding LogSeverity enum case.
    /// If the environment variable is not set or contains an invalid value, the method returns the default log level .trace.
    /// - Returns: A LogSeverity enum case representing the general log level.
    private static func getGeneralLogLevel() -> LogSeverity {
        let generalLogLevelID = "LOG_LEVEL"
        if let generalLogLevelVariable = ProcessInfo.processInfo.environment[generalLogLevelID] {
            if let generalLogLevel = LogSeverity(rawValue: generalLogLevelVariable.lowercased()) {
                return generalLogLevel
            } else {
                print("Invalid LOG_LEVEL environment variable, using trace as fallback")
                return .trace
            }
        }
        return .trace
    }

    /// Gets the log severity level for a given category.
    /// - Parameter category: The category for which to retrieve the log severity level.
    /// - Returns: The log severity level for the given category or nil if no log severity level was found.
    private static func getLogLevel(forCategory category: String) -> LogSeverity? {
        let specificLogLevelID = "LOG_LEVEL_\(category.uppercased())"
        if let specificLogLevelVariable = ProcessInfo.processInfo.environment[specificLogLevelID] {
            if let specificLogLevel = LogSeverity(rawValue: specificLogLevelVariable.lowercased()) {
                return specificLogLevel
            } else {
                print("Invalid \(specificLogLevelID) environment variable")
                return nil
            }
        }
        return nil
    }

    // MARK: - Log implementation
    /**
    Logs a message.
     
     - Parameters:
        - input: The message to log.
        - messageLogLevel: The log severity level for the message. If nil, uses the logger's default log level.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - columns: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
     - Returns: The message that was logged or nil if the message was filtered out based on the log severity level.

     This method logs a message to the console and stores a new LogEntry object with the message content, log severity level, category, function name, and timestamp. The log severity level is determined by the "messageLogLevel" parameter or, if nil, by the logger's default log level. The log entry is then added to the logger's session entries. If the message is filtered out based on the log severity level, the method returns nil. Otherwise, it returns the message that was logged.
    **/
    @discardableResult
    private func log(
        _ input: String,
        _ messageLogLevel: LogSeverity?,
        filename: String,
        line: Int,
        columns: Int,
        functionName: String
    ) -> String? {
        let messageLogLevel = messageLogLevel ?? self.logLevel
        guard messageLogLevel >= self.logLevel else { return nil }

        let logEntryTime: Date
        if #available(macOS 12, *) {
            logEntryTime = Date.now
        } else {
            logEntryTime = Date()
        }

        let message = "\(self.dateFormatter.string(from: logEntryTime)) \(messageLogLevel.alignedDescription) [\(category)\(functionName.isEmpty ? "" : " ")\(functionName)] \(input)"

        print(message)

        self.objectWillChange.send()
        let newLogEntry = LogEntry(
            date: logEntryTime,
            logLevel: messageLogLevel,
            category: category,
            functionName: functionName,
            content: input
        )
        Task { @MainActor in
            ParrotLogger.newLogEntryPublisher.send()
            ParrotLogger.sessionEntries.append(newLogEntry)
        }

        return message
    }

}

extension ParrotLogger.LogSeverity {
    fileprivate var alignedDescription: String {
        switch self {
        case .trace:    return "   TRACE   "
        case .debug:    return "   DEBUG   "
        case .info:     return "    INFO   "
        case .notice:   return "  NOTICE ⚪️"
        case .warning:  return " WARNING 🟡"
        case .error:    return "   ERROR 🔴"
        case .critical: return "CRITICAL ⚫️"
        }
    }
}

// MARK: - Specific level log methods
extension ParrotLogger {
    /**
    Logs a trace message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    public func trace(
        _ message: LogString,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(message.rawString, .trace,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a debug message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    public func debug(
        _ message: LogString,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(message.rawString, .debug,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a info message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    public func info(
        _ message: LogString,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(message.rawString, .info,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a notice message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    public func notice(
        _ message: LogString,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(message.rawString, .notice,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a warning message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    public func warning(
        _ message: LogString,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(message.rawString, .warning,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a error message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    public func error(
        _ message: LogString,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(message.rawString, .error,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a critical message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    public func critical(
        _ message: LogString,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(message.rawString, .critical,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

}

// MARK: - Any
extension ParrotLogger {

    /**
    Logs a trace message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    @_disfavoredOverload
    public func trace(
        _ item: Any,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(String(describing: item), .trace,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a debug message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    @_disfavoredOverload
    public func debug(
        _ item: Any,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(String(describing: item), .debug,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a info message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    @_disfavoredOverload
    public func info(
        _ item: Any,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(String(describing: item), .info,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a notice message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    @_disfavoredOverload
    public func notice(
        _ item: Any,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(String(describing: item), .notice,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a warning message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    @_disfavoredOverload
    public func warning(
        _ item: Any,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(String(describing: item), .warning,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a error message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    @_disfavoredOverload
    public func error(
        _ item: Any,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(String(describing: item), .error,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

    /**
    Logs a critical message.

     - Parameters:
        - message: The message to log.
        - filename: The name of the file from which the message was logged.
        - line: The line number from which the message was logged.
        - column: The column number from which the message was logged.
        - functionName: The name of the function from which the message was logged.
    */
    @_disfavoredOverload
    public func critical(
        _ item: Any,
        filename: String = #fileID,
        line: Int = #line,
        column: Int = #column,
        functionName: String = #function
    ) {
        self.log(String(describing: item), .critical,
                 filename: filename, line: line, columns: column, functionName: functionName)
    }

}

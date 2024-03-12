//
//  ParrotLogger+Export.swift
//  
//
//

import Foundation

extension ParrotLogger {
    static func escapeValue(_ value: String) -> String {

        if value.contains(",") || value.contains("\"") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }

    static func formatDate(_ date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return dateFormatter.string(from: date)
    }

    fileprivate static var logDate: String {
        let date = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd-HH-mm"
        return dateFormatter.string(from: date)
    }

    public enum LogFileType: CaseIterable {
        case txt, csv, xml, json
    }

    /// Saves an array of log entries to a file with the specified file type.
    ///
    /// - Parameters:
    ///   - logEntries: An array of `LogEntry` objects representing the log entries to be saved. If not provided, the default log entries from the session will be used.
    ///   - fileType: A `LogFileType` enumeration value indicating the file format to use for saving the log entries.
    ///   - appName: The name of the application.
    /// - Returns: An optional `URL` pointing to the saved file if the operation is successful; `nil` otherwise.
    public static func saveLogEntries(_ logEntries: [LogEntry] = sessionEntries, to fileType: LogFileType, withAppName appName: String) -> URL? {
        switch fileType {
        case .txt:
            return saveLogToTxt(logEntries, appName: appName)
        case .csv:
            return saveLogToCSV(logEntries, appName: appName)
        case .xml:
            return saveLogToXML(logEntries, appName: appName)
        case .json:
            return saveLogToJSON(logEntries, appName: appName)
        }
    }

    /// Saves an array of log entries to a text file and returns the URL of the saved file.
    ///
    /// - Parameters:
    ///   - logs: An array of `LogEntry` objects representing the log entries to be saved.
    ///   - appName: The name of the application associated with the log entries.
    /// - Returns: An optional `URL` pointing to the location of the saved text file, or `nil` if an error occurred.
    static func saveLogToTxt(_ logs: [LogEntry], appName: String) -> URL? {
        let fileName = "\(appName)-\(logDate).txt"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        let logStrings = logs.map { logEntry -> String in

            let date = formatDate(logEntry.date)
            let logLevel = escapeValue(logEntry.logLevel.rawValue)
            let category = escapeValue(logEntry.category)
            let functionName = escapeValue(logEntry.functionName)
            let content = escapeValue(logEntry.content)

            return "\(date) - \(logLevel) - \(category) - \(functionName) - \(content)\n"
        }

        let joinedString = logStrings.joined(separator: "\n")
        do {
            try joinedString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error while saving array to file: \(error.localizedDescription)")
            return nil
        }
    }

    /// Saves an array of log entries to a CSV file and returns the URL of the saved file.
    ///
    /// - Parameters:
    ///   - logs: An array of `LogEntry` objects representing the log entries to be saved.
    ///   - appName: The name of the application associated with the log entries.
    /// - Returns: An optional `URL` pointing to the location of the saved CSV file, or `nil` if an error occurred.
    static func saveLogToCSV(_ logs: [LogEntry], appName: String) -> URL? {
        let fileName = "\(appName)-\(logDate).txt"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        var csvString = "Date,LogLevel,Category,FunctionName,Content\n"

        for logEntry in logs {
            let date = formatDate(logEntry.date)
            let logLevel = escapeValue(logEntry.logLevel.rawValue)
            let category = escapeValue(logEntry.category)
            let functionName = escapeValue(logEntry.functionName)
            let content = escapeValue(logEntry.content)

            let row = "\(date),\(logLevel),\(category),\(functionName),\(content)\n"
            csvString.append(row)
        }

        do {
            try csvString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error while saving array to file: \(error.localizedDescription)")
            return nil
        }

    }

    /// Saves an array of log entries to an XML file and returns the URL of the saved file.
    ///
    /// - Parameters:
    ///   - logs: An array of `LogEntry` objects representing the log entries to be saved.
    ///   - appName: The name of the application associated with the log entries.
    /// - Returns: An optional `URL` pointing to the location of the saved XML file, or `nil` if an error occurred.
    static func saveLogToXML(_ logs: [LogEntry], appName: String) -> URL? {
        let fileName = "\(appName)-\(logDate).txt"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        var xmlString = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
        xmlString += "<logs>\n"

        for logEntry in logs {
            let date = formatDate(logEntry.date)
            let logLevel = escapeValue(logEntry.logLevel.rawValue)
            let category = escapeValue(logEntry.category)
            let functionName = escapeValue(logEntry.functionName)
            let content = escapeValue(logEntry.content)

            let logXML = """
                <log>
                    <date>\(date)</date>
                    <logLevel>\(logLevel)</logLevel>
                    <category>\(category)</category>
                    <functionName>\(functionName)</functionName>
                    <content>\(content)</content>
                </log>
                """
            xmlString += logXML
        }

        xmlString += "</logs>"

        do {
            try xmlString.write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            print("Error while saving array to file: \(error.localizedDescription)")
            return nil
        }
    }

    /// Saves an array of log entries to a JSON file and returns the URL of the saved file.
    ///
    /// - Parameters:
    ///   - logs: An array of `LogEntry` objects representing the log entries to be saved.
    ///   - appName: The name of the application associated with the log entries.
    /// - Returns: An optional `URL` pointing to the location of the saved JSON file, or `nil` if an error occurred.
    static func saveLogToJSON(_ logs: [LogEntry], appName: String) -> URL? {
        let fileName = "\(appName)-\(logDate).txt"
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(fileName)

        let logsWithoutID = logs.map { logEntry in
            LogEntry(date: logEntry.date, logLevel: logEntry.logLevel, category: logEntry.category, functionName: logEntry.functionName, content: logEntry.content)
        }

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let jsonData = try encoder.encode(logsWithoutID)
            try jsonData.write(to: url)

            return url
        } catch {
            print("Error while saving array to file: \(error.localizedDescription)")
            return nil
        }
    }
}

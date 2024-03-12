//
//  ParrotLogger
//

import Foundation
import os.log

extension ParrotLogger {

    /// /// This enum defines the privacy level for logging messages. It has two cases:
    ///     - `public`: always print the log message
    ///     - `sensitive`: print the log message only when debugging, with additional configuration options to obfuscate sensitive information.
    ///       The configuration options are:
    ///         - `showPrefix`: shows the first n characters of the sensitive information, replacing the rest with asterisks
    ///         - `showSuffix`: shows the last n characters of the sensitive information, replacing the rest with asterisks
    ///         - `showHash`: replaces the sensitive information with a hash value
    ///         - `showAsterisks`: replaces the sensitive information with asterisks of the same length
    ///         - `hide`: completely hides the sensitive information from the log message.
    public enum LogPrivacyLevel {
        /// Always print
        case `public`

        /// Print only when debugging
        case sensitive(SentitivityConfiguration)

        /// This enum defines the different configuration options for obfuscating sensitive information when logging messages with the `LogPrivacyLevel.sensitive` privacy level.
        public enum SentitivityConfiguration {
            case showPrefix(Int)
            case showSuffix(Int)
            case showHash
            case showAsteriscs
            case hide
        }
    }
}

/// This struct represents a string interpolation object that can be used to construct log messages with interpolated values while also respecting the privacy levels defined in `LogPrivacyLevel`.
public struct PrivacyStringInterpolation: StringInterpolationProtocol {
    fileprivate var value: String = ""

    /// Initializes a new instance of `PrivacyStringInterpolation`.
    /// - Parameters:
    ///   - literalCapacity: The minimum number of bytes to allocate for the string.
    ///   - interpolationCount: The number of interpolated values in the string.
    public init(literalCapacity: Int, interpolationCount: Int) {
        self.value.reserveCapacity(literalCapacity)
    }

    /// Appends a literal string to the interpolated string.
    /// - Parameter literal: The literal string to append.
    public mutating func appendLiteral(_ literal: String) {
        self.value.append(literal)
    }

    /// Appends an interpolated value to the string, respecting the privacy level defined in `LogPrivacyLevel`.
    /// - Parameters:
    ///   - item: The item to interpolate.
    ///   - privacy: The privacy level to use when logging the item.
    public mutating func appendInterpolation(_ item: Any, privacy: ParrotLogger.LogPrivacyLevel = .public) {
        switch privacy {
        case .public:
            self.value.append(String(describing: item))
        case .sensitive(let sensitivityConfiguration):
            #if DEBUG
            self.value.append(String(describing: item))
            #else
            switch sensitivityConfiguration {
            case .showPrefix(let prefixSize):
                let itemDescription = String(describing: item)
                let ellipsis = prefixSize < itemDescription.count ? "..." : ""
                self.value.append(itemDescription.prefix(prefixSize).description + ellipsis)
            case .showSuffix(let suffixSize):
                let itemDescription = String(describing: item)
                let ellipsis = suffixSize < itemDescription.count ? "..." : ""
                self.value.append(ellipsis + itemDescription.suffix(suffixSize).description)
            case .showHash:
                self.value.append("<hash: \(String(describing: item).hashValue.description)>")
            case .showAsteriscs:
                self.value.append(String(repeating: "*", count: String(describing: item).count))
            case .hide:
                self.value.append("<private>")
            }
            #endif
        }
    }
}

/// This struct represents a log message that can be constructed from a string interpolation.
/// It conforms to the `ExpressibleByStringInterpolation` protocol to allow for easy creation of log messages with interpolated values.
public struct LogString: ExpressibleByStringInterpolation {
    var rawString: String

    public init(stringInterpolation: PrivacyStringInterpolation) {
        self.rawString = String(stringInterpolation.value)
    }

    public init(unicodeScalarLiteral value: String) {
        self.rawString = String(unicodeScalarLiteral: value)
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.rawString = String(extendedGraphemeClusterLiteral: value)
    }

    public init(stringLiteral value: StringLiteralType) {
        self.rawString = value
    }
}

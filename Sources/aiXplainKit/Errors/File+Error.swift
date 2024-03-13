//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

/// Represents errors that can occur during file operations.
enum FileError: Error {
    
    /// The file size exceeds the maximum allowed limit.
    case fileTooLarge
    
    /// An error occurred while generating the payload for obtaining the pre-signed URL for uploading the file.
    case payloadGenerationFailed(description: String)
    
    /// A localized description of the error.
    var localizedDescription: String {
        switch self {
        case .fileTooLarge:
            return "The file size exceeds the maximum allowed limit."
        case .payloadGenerationFailed(let description):
            return "An error occurred while generating the payload for obtaining the pre-signed URL: \(description)"
        }
    }
}
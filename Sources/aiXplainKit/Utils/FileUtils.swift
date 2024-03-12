//
//  File.swift
//  
//
//  Created by Joao Pedro Monteiro Maia on 11/03/24.
//

import Foundation

internal final class FileUtils {

    func uploadData(from filePath: URL,
                    withTags tags: [String]? = nil,
                    license: License? = nil,
                    asTemporaryFile isTemporaryFile: Bool = true,
                    withMaxAttemptsOf maxAttempts: Int = 2) throws -> URL {

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.fileUpload(isTemporary: isTemporaryFile)
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw NetworkingError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        return URL(string: "")!
//        throw fatalError("Not Implemented yet")

    }
}

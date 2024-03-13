//
//  FileManager.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

/// This class is responsible for managing the file uploads related operations for the Model and Pipeline.
internal final class AiXplainFileManager {

    let networking: Networking = Networking()

    let logger = ParrotLogger(category: "AiXplainKit | FileManager")

    /// Uploads a file located at the specified local URL.
    func uploadFile(at localUrl: URL, temporary: Bool = true, tags: [String: String] = [:], license: License? = nil) async throws {
        if try FileSizeLimit.check(fileAt: localUrl) == false {
            throw FileError.fileTooLarge
        }

        guard let preSignedURL = try await getPreSignedURL(at: localUrl, temporary: temporary, tags: tags, license: license) else {
            return
        }

    }

    /// Obtains a pre-signed URL for uploading the file to the cloud storage.
    ///
    /// - Parameters:
    ///   - localUrl: The local URL of the file to be uploaded.
    ///   - isTemporary: A boolean indicating whether the file is temporary or not.
    ///   - tags: A dictionary containing tags associated with the file.
    ///   - license: The license associated with the file.
    ///
    /// - Returns: The pre-signed URL for uploading the file, or `nil` if an error occurs.
    ///
    /// - Throws:
    ///   - `ModelError.missingBackendURL` if the backend URL is missing.
    ///   - `ModelError.invalidURL` if the constructed URL is invalid.
    ///   - `FileError.couldNotGenerateThePayloadForThePreSignedS3URL` if the payload for obtaining the pre-signed URL cannot be generated.
    ///   - Other errors related to network operations or header construction.
    private func getPreSignedURL(at localUrl: URL, temporary: Bool = true, tags: [String: String] = [:], license: License? = nil) async throws -> URL? {
        let headers: [String: String] = try networking.buildHeader()
        var payload: [String: String] = [:]

        guard let url = APIKeyManager.shared.BACKEND_URL else {
            throw ModelError.missingBackendURL
        }

        let endpoint = Networking.Endpoint.fileUpload(isTemporary: temporary)
        guard let url = URL(string: url.absoluteString + endpoint.path) else {
            throw ModelError.invalidURL(url: url.absoluteString + endpoint.path)
        }

        if temporary {
            payload = ["contentType": localUrl.mimeType(), "originalName": localUrl.lastPathComponent]
        } else {
            payload = ["contentType": localUrl.mimeType(), "originalName": localUrl.lastPathComponent, "tags": tags.map { "\($0.key),\($0.value)" }.joined(separator: "\n") ?? "", "license": license?.name ?? ""]
        }

        guard let jsonPayload = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            logger.error("Could not generate the payload to obtain the S3 Pre Signed URL: \(String(describing: payload))")
            throw FileError.payloadGenerationFailed(description: String(describing: payload))
        }

        logger.debug("Creating a temp URL with the following payload:\(payload.description)")
        let response = try await networking.post(url: url, headers: headers, body: jsonPayload)

        //        print(String(data: response.0, encoding: .utf8))

        return nil

    }

}

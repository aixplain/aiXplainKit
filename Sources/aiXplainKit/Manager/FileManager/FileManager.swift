//
//  FileManager.swift
//
//
//  Created by Joao Pedro Monteiro Maia on 12/03/24.
//

import Foundation

/// This class is responsible for managing the file uploads related operations for the Model and Pipeline.
internal final class FileUploadManager {

    let networking: Networking
    let logger: ParrotLogger

    init() {
        self.networking = Networking()
        self.logger = ParrotLogger(category: "AiXplainKit | FileManager")
    }

    init(networking: Networking) {
        self.networking = networking
        self.logger =  ParrotLogger(category: "AiXplainKit | FileManager")
    }

    // Uploads a file located at the specified local URL.
    /// - Parameters:
    ///   - localFileURL: The local URL of the file to be uploaded.
    ///   - isTemporary: A boolean indicating whether the file is temporary or not.
    ///   - tags: A dictionary containing tags associated with the file.
    ///   - license: The license associated with the file.
    /// - Returns: The URL of the uploaded file in cloud storage.
    /// - Throws:
    ///   - `FileUploadError.fileSizeExceedsLimit` if the file size exceeds the maximum allowed limit.
    ///   - Other errors related to networking, payload generation, or missing bucket name.
    func uploadFile(at localUrl: URL, temporary: Bool = true, tags: [String: String] = [:], license: License? = nil) async throws -> URL {
        if try FileSizeLimit.check(fileAt: localUrl) == false {
            logger.error(FileError.fileSizeExceedsLimit.localizedDescription)
            throw FileError.fileSizeExceedsLimit
        }

        let headers = ["Content-Type": localUrl.mimeType()]

        let payload = try Data(contentsOf: localUrl)

        let preSignedURL = try await getPreSignedURL(at: localUrl, temporary: temporary, tags: tags, license: license)

        let response = try await networking.put(url: preSignedURL, body: payload, headers: headers)

        guard let httpResponse = response.1 as? HTTPURLResponse else {
            logger.error(NetworkingError.invalidHttpResponse.localizedDescription)
            throw NetworkingError.invalidHttpResponse
        }

        if httpResponse.statusCode != 200 {
            logger.error(NetworkingError.invalidStatusCode(statusCode: httpResponse.statusCode).localizedDescription)
            throw NetworkingError.invalidStatusCode(statusCode: httpResponse.statusCode)
        }

        logger.info("Successfully uploaded \(localUrl.lastPathComponent) to cloud storage")

        let s3Link = try constructS3Link(from: preSignedURL)
        guard let s3URL = URL(string: s3Link) else {
            throw FileError.bucketNameNotFound // TODO: Proper Error
        }

        return s3URL
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
    private func getPreSignedURL(at localUrl: URL, temporary: Bool = true, tags: [String: String] = [:], license: License? = nil) async throws -> URL {
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
            payload = ["contentType": localUrl.mimeType(), "originalName": localUrl.lastPathComponent, "tags": tags.map { "\($0.key),\($0.value)" }.joined(separator: "\n"), "license": license?.name ?? ""]
        }

        guard let jsonPayload = try? JSONSerialization.data(withJSONObject: payload, options: []) else {
            logger.error("Could not generate the payload to obtain the S3 Pre Signed URL: \(String(describing: payload))")
            throw FileError.payloadGenerationFailed(description: String(describing: payload))
        }

        logger.debug("Creating a temp URL with the following payload:\(payload.description)")
        let response = try await networking.post(url: url, headers: headers, body: jsonPayload)

        if let json = try? JSONSerialization.jsonObject(with: response.0, options: []) as? [String: Any] {
            if let uploadUrl = json["uploadUrl"] as? String {
                logger.debug("Pre-Signed URL: \(uploadUrl)")
                guard let url = URL(string: uploadUrl) else {
                    throw FileError.couldNotGetTheS3PreSignedURL
                }
                return url
            }
        }

        throw FileError.couldNotGetTheS3PreSignedURL
    }

    /// Extracts the bucket name from the pre-signed URL and constructs the S3 link.
    ///
    /// - Parameter presignedUrl: The pre-signed URL containing the bucket name.
    /// - Returns: The constructed S3 link.
    /// - Throws: An error if the bucket name cannot be extracted from the pre-signed URL.
    private func constructS3Link(from presignedUrl: URL) throws -> String {

        let pattern = "https://(.*?).s3.amazonaws.com"

        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            throw NetworkingError.invalidURL(url: nil)
        }

        let range = NSRange(presignedUrl.absoluteString.startIndex..<presignedUrl.absoluteString.endIndex, in: presignedUrl.absoluteString)
        guard let match = regex.firstMatch(in: presignedUrl.absoluteString, options: [], range: range),
              let bucketNameRange = Range(match.range(at: 1), in: presignedUrl.absoluteString)
        else {
            throw FileError.bucketNameNotFound
        }

        let bucketName = String(presignedUrl.absoluteString[bucketNameRange])

        let path = presignedUrl.path.dropFirst() // Remove the leading '/'
        let s3Link = "s3://\(bucketName)/\(path)"

        return s3Link
    }

}
